#!/usr/bin/env ruby

require 'sinatra'

# Configuration
#
# The keying off of REDISTOGO_URL allows this to be deployed both 
# locally and on Heroku without needing to change the Redis initialization
# code back and forth.
configure do
  require 'redis'
  env = ENV["REDISTOGO_URL"]
  if env
    uri = URI.parse(env)
    REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  else
    REDIS = Redis.new
  end
  REDIS.setnx 'next', 10 * 36**4 # start with a0000
end

# basic index navigation page
get '/' do
  # display index
  erb :index
end

# poll creation page, using previously entered parameters
get '/create' do
  @numquestions = 1
  @numanswers = 1
  erb :create
end

# store the poll to a unique key
post '/finalize' do
  # storing poll goes here
  @hp = request.host_with_port
  @next = REDIS.get('next').to_i
  @key = @next.to_s(36)
  @next += rand(10) + 1 # new key'
  @poll = params[@key]
  @pollhash = REDIS.hgetall "poll:#{@poll}"
  REDIS.set 'next', @next.to_s

  poll = Hash.new # new hash, this will be stored in REDIS
  topic = params[:topic]
  @colorb = params[:colorb]
  @colort = params[:colort]
  @colord = params[:colord]
  if topic
    # this means we have some form data
    poll[:topic] = topic
    poll[:colorb] = @colorb
    poll[:colort] = @colort
    poll[:colord] = @colord
    REDIS.hset "poll:#{@key}", "topic", topic
    REDIS.hset "poll:#{@key}", "colorb", @colorb
    REDIS.hset "poll:#{@key}", "colort", @colort
    REDIS.hset "poll:#{@key}", "colord", @colord
    i = 1
    qsym = ("q"+i.to_s).to_sym
    while params[qsym]
      poll[qsym] = params[qsym]
      REDIS.hset "poll:#{@key}", qsym.to_s, params[qsym]
      j = 1
      asym = (qsym.to_s+"a"+j.to_s).to_sym
      while params[asym]
        poll[asym] = params[asym]
        REDIS.hset "poll:#{@key}", asym.to_s, params[asym]
        REDIS.hset "results:#{@key}", asym.to_s, "0"
        j += 1
        asym = (qsym.to_s+"a"+j.to_s).to_sym
      end
      i += 1
      qsym = ("q"+i.to_s).to_sym
    end
    erb :finalize
  else
    erb :finalerror
  end
end

# retrieve poll 'poll' and display for a visitor to take
['/poll', '/poll/:poll'].each do |route|
  get route do
    @poll = params[:poll]
    @pollhash = REDIS.hgetall "poll:#{@poll}"
    if @pollhash["topic"]
      erb :takepoll
    else
      erb :pollerror
    end
  end
  post route do
    @hp = request.host_with_port
    @poll = params[:poll]
    i = 1
    gsym = "q" + i.to_s
    while params[gsym]
      REDIS.hincrby "results:#{@poll}", params[gsym], 1
      i += 1
      gsym = "q" + i.to_s
    end
    erb :polltaken
  end
end

# retrieve the poll results
['/results', '/results/:poll'].each do |route|
  get route do
    # display current stats on poll 'poll'
    @poll = params[:poll]
    @pollhash = REDIS.hgetall "poll:#{@poll}"
    @resultshash = REDIS.hgetall "results:#{@poll}"
    if @pollhash["topic"]
      erb :results
    else
      erb :resultserror
    end
  end
end

# error case
not_found do
  @hp = request.host_with_port
  erb :notfound
end

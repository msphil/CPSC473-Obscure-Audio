#!/usr/bin/env ruby

require 'sinatra'
require 'redis'

# TODO:
#   Break pages out into views
#   Fancier main page
#   Tidy up page displays

configure do
  REDIS = Redis.new
  REDIS.setnx 'next', 10 * 36**4 # start with a0000
end

# cheesy temporary hack to allow clearing of database
# TODO
#   ** REMOVE BEFORE DEPLOYMENT **
get '/flushdb' do
  REDIS.flushdb
  "Flushed!  (Hope there wasn't anything important there!)"
end

get '/' do
  # display index
  erb :index
end


# initial poll parameters page
get '/create' do
  # get number of questions, and answers per question
  erb :create
end

# poll creation page, using previously entered parameters
post '/create' do
  @numquestions = params[:numquestions].to_i
  @numanswers = params[:numanswers].to_i
  erb :create2
end

# store the poll to a unique key
post '/finalize' do
  # storing poll goes here
  @hp = request.host_with_port
  @next = REDIS.get('next').to_i
  @key = @next.to_s(36)
  @next += rand(10) + 1 # new key
  REDIS.set 'next', @next.to_s

  poll = Hash.new # new hash, this will be stored in REDIS
  topic = params[:topic]
  if topic
    # this means we have some form data
    poll[:topic] = topic
    REDIS.hset "poll:#{@key}", "topic", topic
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
get '/poll/:poll' do
  @poll = params[:poll]
  @pollhash = REDIS.hgetall "poll:#{@poll}"
  if @pollhash["topic"]
    erb :takepoll
  else
    erb :pollerror
  end
end

# store the results from the poll which was just taken
post '/poll/:poll' do
  @hp = request.host_with_port
  @poll = params[:poll]
  i = 1
  gsym = "q" + i.to_s
  while params[gsym]
    result = (REDIS.hget "results:#{@poll}", params[gsym]).to_i
    result += 1
    REDIS.hset "results:#{@poll}", params[gsym], result.to_s
    i += 1
    gsym = "q" + i.to_s
  end
  erb :polltaken
end

get '/results/:poll' do
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

not_found do
  @hp = request.host_with_port
  erb :notfound
end

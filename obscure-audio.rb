#!/usr/bin/env ruby

require 'sinatra'
require 'redis'

# TODO:
#   Fancier main page
#   Form for poll entry
#   Poll display
#   Poll results
#   Tidy up page displays

configure do
  REDIS = Redis.new
  REDIS.setnx 'key', 10 * 36**4
end

get '/' do
  # display index
  erb :index
end

get '/create' do
  # create poll with new hash here
  #
  # placeholder:
  erb :index
end

get '/poll' do
  # poll form goes here
  #
  # placeholder:
  erb :index
end

get '/poll/:poll' do
  # retrieve poll 'poll' and display for a visitor to take
  #
  # placeholder:
  erb :index
end

get '/results/:poll' do
  # display current stats on poll 'poll'
  #
  # placeholder:
  erb :index
end

__END__
@@index
<!DOCTYPE html>
<html>
  <head>
    <title>Obscure Audio Internet Poll Creator</title>
  </head>
  <body>
    <p><a href="create">Create a poll</a></p>
    <p><a href="poll">Take a poll</a></p>
    <p><a href="results">View poll results</a></p>
  </body>
</html>

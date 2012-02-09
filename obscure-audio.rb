#!/usr/bin/env ruby

require 'sinatra'
require 'redis'

# TODO:
#   Break pages out into views
#   Fancier main page
#   Form for poll entry
#   Poll display
#   Poll results
#   Tidy up page displays

configure do
  REDIS = Redis.new
  REDIS.setnx 'key', 10 * 36**4 # start with a0000
end

get '/' do
  # display index
  erb :index
end

get '/create' do
  # create poll with new hash here

  @numquestions = params[:numquestions].to_i
  if @numquestions < 1
    erb :create
  else
    erb :create2
  end
end

#post '/create:numquestions' do
#  @numquestions = params[:numquestions]
#  erb :create2
#end

post '/finalize' do
  # storing poll goes here
  @key = REDIS.get('key').to_i
  @key += random 10 # new key
  REDIS.set 'key', @key.to_s(36)
  erb :final
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

not_found do
  @hp = request.host_with_port
  erb :notfound
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

@@notfound
<!DOCTYPE html>
<html>
  <head>
    <title>Obscure Audio Internet Poll Creator</title>
  </head>
  <body>
    <p>You have reached an invalid location.</p>
    <p>Please return to <a href="http://<%= @hp %>">the index</a></p>
  </body>
</html>

@@create
<!DOCTYPE html>
<html>
  <head>
    <title>Obscure Audio Internet Poll Creator</title>
  </head>
  <body>
    <form>
      Number of questions: 
        <input type="text" name="numquestions">
    </form>
  </body>
</html>

@@create2
<!DOCTYPE html>
<html>
  <head>
    <title>Obscure Audio Internet Poll Creator</title>
  </head>
  <body>
    <form>
      <p>Poll Question:
        <input type="text" name="question" size="40">
      </p>
      <% 1.upto(@numquestions) { |i|  %>
        <p>Question <%= i %>:
          <input type="text" name="question<%= i %>" size="40">
        </p>
      <% } %>
    </form>
  </body>
</html>

@@finalize
<!DOCTYPE html>
<html>
  <head>
    <title>Obscure Audio Internet Poll Creator</title>
  </head>
  <body>
    <p>You created poll <%= @key %>, which may be accessed <a href="http://<%= @hp =>/poll/<%= @key %>">here</a>.
  </body>
</html>


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
  REDIS.setnx 'next', 10 * 36**4 # start with a0000
end

get '/' do
  # display index
  erb :index
end

get '/create' do
  # create poll with new hash here
  erb :create
end

post '/create' do
  @numquestions = params[:numquestions].to_i
  @numanswers = params[:numanswers].to_i
  erb :create2
end

post '/finalize' do
  # storing poll goes here
  @hp = request.host_with_port
  @next = REDIS.get('next').to_i
  @key = @next.to_s(36)
  @next += rand(10) + 1 # new key
  REDIS.set 'next', @next.to_s
  erb :finalize
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
    <form method="POST">
      <p>Number of questions: 
        <input type="text" name="numquestions" /></p>
      <p>Number of answers per question: 
        <input type="text" name="numanswers" /></p>
      <input type="submit" />
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
    <form method="POST" action="/finalize">
      <p>Poll Question:
        <input type="text" name="question" size="40" />
      </p>
      <% 1.upto(@numquestions) { |i|  %>
        <p>Question <%= i %>:
          <input type="text" name="q<%= i %>" size="40" /><br>
          <% 1.upto(@numanswers) { |j|  %>
            Q<%= i %>, Answer <%= j %>
            <input type="text" name="q<%= i %>a<%= j %>" size="40" /><br>
          <% } %>
        </p>
      <% } %>
      <input type="submit" />
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
    <p>You created poll <%= @key %>, which may be accessed <a href="http://<%= @hp %>/poll/<%= @key %>">here</a>.
  </body>
</html>


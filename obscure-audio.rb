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
      <p>Poll Topic:
        <input type="text" name="topic" size="40" />
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

@@finalerror
<!DOCTYPE html>
<html>
  <head>
    <title>Obscure Audio Internet Poll Creator - ERROR!</title>
  </head>
  <body>
    <p>The data submitted to create a poll could not be stored or was otherwise problematic.  Please try again...</p>
  </body>
</html>

@@takepoll
<!DOCTYPE html>
<html>
  <head>
    <title>Obscure Audio Internet Poll Creator</title>
  </head>
  <body>
    <h1><%= @pollhash["topic"] %></h1>
    <form method="POST">
    <% i = 1 %>
    <% qstr = "q" + i.to_s %>
    <% while @pollhash[qstr] %>
      <p><%= @pollhash[qstr] %></p>
      <% j = 1 %>
      <% astr = qstr + "a" + j.to_s %>
      <% while @pollhash[astr] %>
        <p><input type="radio" name="<%= qstr %>" value="<%= astr %>"><%= @pollhash[astr] %></p>
        <% j += 1 %>
        <% astr = qstr + "a" + j.to_s %>
      <% end %>
      <% i += 1 %>
      <% qstr = "q" + i.to_s %>
    <% end %>
    <input type="submit" />
    </form>
  </body>
</html>

@@polltaken
<!DOCTYPE html>
<html>
  <head>
    <title>Obscure Audio Internet Poll Creator</title>
  </head>
  <body>
    <p>Thank you!</p>
    <p>Your answers have been added to <a href="<%= @hp %>/results/<%= @poll %>">the results</a> for this poll.</p>
  </body>
</html>

@@pollerror
<!DOCTYPE html>
<html>
  <head>
    <title>Obscure Audio Internet Poll Creator - ERROR!</title>
  </head>
  <body>
    <p>There is no poll "<%= @poll %>" available.</p>
  </body>
</html>

@@results
<!DOCTYPE html>
<html>
  <head>
    <title>Obscure Audio Internet Poll Creator</title>
  </head>
  <body>
    <h1><%= @pollhash["topic"] %></h1>
    <% i = 1 %>
    <% qstr = "q" + i.to_s %>
    <% while @pollhash[qstr] %>
      <p><%= @pollhash[qstr] %></p>
      <% j = 1 %>
      <% astr = qstr + "a" + j.to_s %>
      <% while @pollhash[astr] %>
        <p>-- <%= @pollhash[astr] %>: <%= @resultshash[astr] %></p>
        <% j += 1 %>
        <% astr = qstr + "a" + j.to_s %>
      <% end %>
      <% i += 1 %>
      <% qstr = "q" + i.to_s %>
    <% end %>
  </body>
</html>

@@resultserror
<!DOCTYPE html>
<html>
  <head>
    <title>Obscure Audio Internet Poll Creator - ERROR!</title>
  </head>
  <body>
    <p>There is no poll "<%= @poll %>" available, so there are no results.</p>
  </body>
</html>


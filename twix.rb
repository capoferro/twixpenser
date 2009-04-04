#! /usr/bin/ruby

require 'rubygems'
gem 'twitter4r'
require 'twitter'
require 'yaml'
#work around for "undefined method parse"
require 'time'

##
# Read in everything twixpenser will need to post to the google form.
##
twixpenser = YAML::load_file('twix.conf.yml')

##
# Check if the logfile already exists. If not, create it.
##
if File.exists?('logfile')
  logfile = File.new('logfile', 'r+')
  lines = logfile.readlines

  line_number = lines.length-1
  looking_for_date = true
  while looking_for_date and line_number > 0
    begin
      looking_for_date = false
      puts last_date = Time.parse(lines[line_number])
    rescue
      line_number -= 1
      looking_for_date = true
    end
  end

  if looking_for_date
    puts "ERROR: DATE NOT FOUND IN logfile"
    last_date = Time.parse('1/1/2009')
  end

else
  logfile = File.new('logfile', 'w')
  last_date = Time.parse('1/1/2009')
end

##
# Retrieve tweets
##
client = Twitter::Client.new(:login => twixpenser[:account], 
                             :password => twixpenser[:pass])
received_messages = client.messages(:received)

##
# Process tweets
##
processed_tweets_flag = false
tweets_to_file = []
received_messages.each { |tweet|

  ##
  # Check when the last twix.rb was successfully run.
  ##
  if last_date >= tweet.created_at
    puts 'No more new tweets!'
    break
  ##
  # If it's a help request, send back help reply
  ##
  elsif tweet.to_s.chomp == 'help'
    client.message(:post, "Format for expense: d #{twixpenser[:account]} <cost>!<item>!<description>", tweet.sender.name)
    break
  end
  
  begin
    ##
    # Split the tweet on !s.  No ! allowed in the description.
    ##
    split_tweet = tweet.text.split('!')
    cost = split_tweet[0].chomp
    item = split_tweet[1].chomp
    desc = split_tweet[2].chomp
    if split_tweet.length > 3
      client.message(:post, "\"!\" are not allowed in the description section.  Some data may not have been sorted.")
    end
    user = tweet.sender.name

    curl = "curl -s -d 'entry.1.single=#{item}&entry.2.single=#{desc}&entry.3.single=#{cost}&entry.4.group=#{user}&entry.5.single=#{tweet.text}' #{twixpenser[:url]} > twixlogs/curl#{tweet.created_at.strftime("%Y-%m-%dT%H:%M:%S")}.log"

    puts tweet
    processed_tweets_flag = true
    tweets_to_file << tweet
    Kernel.system(curl)
  rescue
    client.message(:post, "Invalid: #{tweet}", tweet.sender.screen_name)
    client.message(:post, "d #{twixpenser[:account]} <cost>!<item>!<description>", tweet.sender.screen_name)
    tweets_to_file << 'ERROR: ' + tweet.to_s
    processed_tweets_flag = true
  end 

}

if processed_tweets_flag
  logfile.puts 'vvvvvvvvvvvvvvvvv'
  tweets_to_file.each { |tweet|
    logfile.puts tweet
  }
  logfile.puts '--retrieved at:--'
  logfile.puts Time.now
end


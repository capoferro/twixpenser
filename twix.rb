#! /usr/bin/ruby

require 'rubygems'
gem 'twitter4r'
require 'twitter'
#work around for "undefined method parse"
require 'time'


##
form_url = 'http://spreadsheets.google.com/formResponse?formkey=cHVoZkhUX2ZWUmVLUW83d011UzdfUnc6MA..'
twitter_account = 'jkagbills'
twitter_pass = 'aznapt'
##

if File.exists?('logfile')
  logfile = File.new('logfile', 'r+')
  lines = logfile.readlines
  last_date = Time.parse(lines[lines.length-1])
else
  logfile = File.new('logfile', 'w')
  last_date = Time.parse('1/1/2009')
end

client = Twitter::Client.new(:login => twitter_account, :password => twitter_pass)
received_messages = client.messages(:received)
# d <twitter_account> <cost>!item!description
received_messages.each { |tweet|
  if last_date >= tweet.created_at
    puts 'No new tweets!'
    break
  end
  
  begin
    split_tweet = tweet.text.split('!')
    cost = split_tweet[0].chomp
    item = split_tweet[1].chomp
    desc = split_tweet[2].chomp
    user = tweet.sender.name
  rescue
    client.message(:post, "Invalid: #{tweet}", tweet.sender.screen_name)
    break
  end
  curl = "curl -ds 'entry.1.single=#{item}&entry.2.single=#{desc}&entry.3.single=#{cost}&entry.4.group=#{user}&entry.5.single=#{tweet.text}' #{form_url}" 

  puts curl
  Kernel.system(curl)
}

flag = false
tweets_to_file = []
received_messages.each{ |tweet|
  if last_date >= tweet.created_at
    break
  end
  flag = true
  tweets_to_file << tweet
}
if flag
  logfile.puts 'vvvvvvvvvvvvvvvvv'
  puts
  puts
  puts 'Processed:'
  tweets_to_file.each { |tweet|
    puts "\t#{tweet}"
    logfile.puts tweet
  }
  logfile.puts '--retrieved at:--'
  logfile.puts Time.now
end


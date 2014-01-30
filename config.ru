$:.unshift(File.expand_path("../lib", __FILE__))
$:.unshift(File.expand_path("../app", __FILE__))

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __FILE__)

require "rubygems"
require "bundler/setup"

require "cloud_controller"

puts "Running config.ru"
#app = VCAP::CloudController::Runner.new(ARGV).get_app!
#puts "Got app: #{app.inspect}"
#run app
run Sinatra::Base
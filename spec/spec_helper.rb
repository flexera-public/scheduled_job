require 'pry'
require 'simplecov'
SimpleCov.start

require 'bundler/setup'
Bundler.setup

require_relative '../db/connect'
Db::Connect.init

require 'scheduled_job' # and any other gems you need
require 'logger'

ScheduledJob.configure do |config|
  config.logger = Logger.new(nil)
end

RSpec.configure do |config|
    # some (optional) config here
end

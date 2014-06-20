require 'bundler/setup'
Bundler.setup

require 'scheduled_job' # and any other gems you need
require 'logger'

ScheduledJob.configure do |config|
  config.logger = Logger.new(nil)
end

RSpec.configure do |config|
    # some (optional) config here
end

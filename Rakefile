require "bundler/gem_tasks"
require 'rspec/core/rake_task'

require_relative 'db/connect'
require 'scheduled_job'

RSpec::Core::RakeTask.new('spec')
Dir[File.dirname(__FILE__) + '/lib/tasks/**/*.rake'].each { |file| import file }

task :default => :spec

desc "console"
task :console => :dbconnect do
  require 'pry'
  binding.pry # rubocop:disable Lint/Debugger
end

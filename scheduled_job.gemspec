# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'scheduled_job/version'

Gem::Specification.new do |spec|
  spec.name          = "scheduled_job"
  spec.version       = ScheduledJob::VERSION
  spec.authors       = ["CallumD", "aliscott", "smcgivern", "alikhajeh1"]
  spec.email         = ["callum.dryden@rightscale.com", "alistair@rightscale.com", "sean.mcgivern@rightscale.com", "ali@rightscale.com"]
  spec.summary       = %q{Adding support for jobs that need to reccur}
  spec.description   = %q{By including the scheduled job module in a delayed job you can specify when you would like the job to run again. Currently this is intented to be used with the active record back end this may change in future.}
  spec.homepage      = "https://github.com/rightscale/scheduled_job"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "delayed_job", "< 4.2"
  spec.add_runtime_dependency "delayed_job_active_record", "< 4.2"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "~> 0.9"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "sqlite3", "~> 1.3.10"
  spec.add_development_dependency 'coveralls'
end

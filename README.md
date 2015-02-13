# ScheduledJob

[![Build Status](https://travis-ci.org/rightscale/scheduled_job.svg?branch=master)](https://travis-ci.org/rightscale/scheduled_job)

Scheduled job looks to build on top of the [delayed_job](https://github.com/collectiveidea/delayed_job) project by adding support for jobs that need to recur. Whilst investigating other options we decided that we wanted a very light weight framework that would simply allow us to define worker tasks that need to happen on a regular basis.

In order to achieve this we created the following interface which allows the developer to consisly define what the job is to do as well as when it is to run. This helps keep all the logic in one place which is a huge plus.

In terms of implementation there are only a couple of things we need to do.

Firstly if there are any before or success callbacks you need to define you can do this via the configure block. This passes the instance of DelayedJob that run your job as well as the job itself.

We can also take this opportunity to set up any logging. By default we use the ruby logger but if you are using rails for example you can do something like the following:

```ruby
ScheduledJob.configure do |config|
  config.before_callback = -> (job, scheduled_job) do
    JobRunLogger.update_attributes!(job_name: scheduled_job.class.name, started_at: Time.now.utc)
  end

  config.success_callback = -> (job, _) do
    ScheduledJob.logger.info("Hurrah my job #{job.id} has completed")
  end

  config.logger = Rails.logger
end
```

With this in place we can go on to define a job that we want to run regularly. To do this just mix in the scheduled job module in your class, define a perform method and define a time to recur.

```ruby
class WeeklyMetricJob
  include ::ScheduledJob

  def perform
    ScheduledJob.logger.info('I need to do something over and over')
  end

  def self.time_to_recur(last_run_at)
    last_run_at.end_of_week + 3.hours
  end
end
```

This allows you so specify what logic you need to run along side how often it needs to run. The time to recur is passed the completion time of the last successful run so you can use whatever logic you like in here to define when the job needs to run again.

Finally you need to kick off the job the first time. Once it has run successfully it will look after itself but to start the cycle you need to run schedule_job on your job. Continuing on the example above:

```ruby
WeeklyMetricJob.schedule_job
```

Note currently this implementation is dependant upon using the [delayed_job_active_record](https://github.com/collectiveidea/delayed_job_active_record) backend. This is something that we may be looking to remove in future.

## Running the specs

This is the default rake task so you can run the specs in any of the following ways:

```bash
bundle exec rake
bundle exec rake spec
bundle exec rspec
```

## Getting a console

The project is currently using pry. In order to get a console in the context of the project just run the pry.rb file in ruby.

```bash
bundle exec ruby pry.rb
```

## Installation

Add this line to your application's Gemfile:

    gem 'scheduled_job'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install scheduled_job

## Usage

First you must include the scheduled job module in any DelayedJob that needs to run on a regular basis.

```ruby
include ::ScheduledJob
```

Then you need to say what the job is actually to do. This is done by implementing the perform method.

```ruby
def perform
  puts 'I do work!'
end
```

Finally we need to write the logic for when we want the job to run. This is done by implementing the time_to_recur method which is passed the time the job last completed as its parameter.

```ruby
def self.time_to_recur(last_run_at)
  last_run_at + 3.hours
end
```

Recently added is the new jobs configuration. This adds two major new benefits. Firstly this will allow you to define jobs that are allow to run in multiple instances. Say for example that there should always be two instances of a given job running. This can now be defined using the following configuration:

```ruby
ScheduledJob.configure do |config|
  config.jobs = {
    MyAwesomeParallelJobClass => { count: 2 }
  }
end
```

This lets scheduled job know that it is OK to have two pending job instances for MyAwesomeParallelJobClass in the delayed job table. Additionally by using this configuration you also get access to the new reschedule rake task for free. ScheduledJob now adds `rake jobs:reschedule`. This will loop through your jobs configuration and automatically call schedule job up to the number of times you intend the jobs pending. This is useful for heavy users of scheduled job to "prime" your database with your recurring jobs. Note you can still add jobs to this configuration that you do not want any instances of by setting the count to 0. This is useful if you are looking to access all classes you have that you have registered with scheduled job.

There are also callbacks that are available using ScheduledJob. These allow you to hook into the scheduling life cycle. Also note that as this uses DelayedJob under the hood all of the delayed job callbacks are still available for use.

These can be defined when configuring the gem for you application on the configure block:

```ruby
ScheduledJob.configure do |config|
  # configuration code in here
end
```

The before_callback is executed before the perform method is called on the scheduled job. This is passed the delayed job object and the scheduled job instance.

```ruby
config.before_callback = -> (job, scheduled_job) do
  JobRunLogger.update_attributes!(job_name: scheduled_job.class.name, started_at: Time.now.utc)
end
```

The success_callback is called on successful completion of the job and is also passed the delayed job object and the scheduled job instance.

```ruby
config.success_callback = -> (job, _) do
  ScheduledJob.logger.info("Hurrah my job #{job.id} has completed")
end
```

Then there is the fast mode. This is checked prior to scheduling another run of your job e.g. after a job has completed. This allows you to override the scheduling logic and ask the job to run immediately. This is passed the scheduled job class. This means you can have state stored elsewhere to change the scheduling without having to modify the code. This could be getting an array from a database for example:

```ruby
config.fast_mode = -> (job) do
  Database.get_value('fast_mode_jobs').include?(job.name)
end
```

## Contributing

1. Fork it ( https://github.com/rightscale/scheduled_job/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Maintained by

- [Callum Dryden](https://github.com/CallumD)
- [Alistair Scott](https://github.com/aliscott)
- [Sean McGivern](https://github.com/smcgivern)
- [Ali Khajeh-Hosseini](https://github.com/alikhajeh1)

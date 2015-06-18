require "scheduled_job/version"
require 'logger'
require 'delayed_job'
require 'delayed_job_active_record'
require File.dirname(__FILE__) + '/tasks/jobs.rb'

module ScheduledJob
  class ConfigError < StandardError
  end

  class << self
    attr_writer :config
    def config
      @config ||= Config.new
    end
  end

  def self.reschedule
    config.jobs.each do |job, options|
      options[:count].times do
        job = job.to_s if job.is_a?(Symbol)
        job = job.constantize if job.is_a?(String)
        job.schedule_job
      end
    end if config.jobs
  end

  def self.logger
    self.config.logger
  end

  def self.configure
    yield(config)
    validate_job_hash(config.jobs) if config.jobs
  end

  def self.validate_job_hash(jobs)
    jobs.each do |klass, options|
      raise ConfigError.new("Jobs config found invalid class: #{klass}") unless klass.is_a?(Class) || klass.is_a?(Symbol) || klass.is_a?(String)
      raise ConfigError.new("Jobs config found invalid job count: #{options[:count]}") unless options[:count].to_i >= 0
    end
  end

  class Config
    attr_accessor :logger, :before_callback, :success_callback, :fast_mode, :jobs

    def initialize
      @jobs ||= {}
      @logger = Logger.new(STDOUT)
    end
  end

  def self.included(base)
    base.extend ScheduledJobClassMethods
  end

  def before(job)
    callback = ScheduledJob.config.before_callback
    callback.call(job, self) if callback
  end

  @params = nil
  def success(job)
    callback = ScheduledJob.config.success_callback
    callback.call(job, self) if callback
    GC.start
    self.class.schedule_job(job, @params)
  end

  def failure(job)
    ScheduledJob.logger.error("DelayedJob failed: processing job in queue #{self.class.queue_name} failed")
    job.update_attributes!(:failed_at => Time.now)
    self.class.schedule_job(nil, @params)
  end

  def error(job, exception)
    ScheduledJob.logger.warn("DelayedJob error: Job: #{job.id}, in queue #{self.class.queue_name}, exception: #{exception}")
    self.class.schedule_job(nil, @params)
  end

  module ScheduledJobClassMethods
    # This method should be called when scheduling a recurring job as it checks to ensure no
    # other instances of the job are already running.

    def schedule_job(job = nil, params = nil)
      if can_schedule_job?(job)
        callback = ScheduledJob.config.fast_mode
        in_fast_mode = callback ? callback.call(self) : false

        run_at = in_fast_mode ? Time.now.utc + 1 : time_to_recur(Time.now.utc)

        if params
          Delayed::Job.enqueue(new(*params), :run_at => run_at, :queue => queue_name)
        else
          Delayed::Job.enqueue(new, :run_at => run_at, :queue => queue_name)
        end
      end
    end

    def random_minutes(base, random_delta)
      random_delta *= -1 if random_delta < 0
      (base + Random.new.rand((-1 * random_delta)..random_delta)).minutes
    end

    def can_schedule_job?(job = nil)
      conditions = ['(handler like ? OR handler like ?) AND failed_at IS NULL', "%:#{self.name} %", "%:#{self.name}\n%"]
      unless job.blank?
        conditions[0] << " AND id != ?"
        conditions << job.id
      end
      job_count = Delayed::Job.where(conditions).count
      intended_job_count = 1

      if ScheduledJob.config.jobs && ScheduledJob.config.jobs[self.name]
        intended_job_count = ScheduledJob.config.jobs[self.name][:count]
      end

      job_count < intended_job_count
    end

    def run_duration_threshold
      self.const_defined?(:RUN_DURATION_THRESHOLD) ? self::RUN_DURATION_THRESHOLD : nil
    end

    def queue_name
      Delayed::Worker.default_queue_name
    end
  end
end

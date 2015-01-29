require "scheduled_job/version"
require 'logger'
require 'delayed_job'
require 'delayed_job_active_record'

module ScheduledJob
  class << self
    attr_writer :config
    def config
      @config ||= Config.new
    end
  end

  def self.logger
    self.config.logger
  end

  def self.configure
    yield(config)
  end

  class Config
    attr_accessor :logger, :before_callback, :success_callback, :fast_mode

    def initialize
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

  def success(job)
    callback = ScheduledJob.config.success_callback
    callback.call(job, self) if callback
    GC.start
    self.class.schedule_job(job)
  end

  def failure(job)
    ScheduledJob.logger.error("DelayedJob failed: processing job in queue #{self.class.queue_name} failed")
    job.update_attributes!(:failed_at => Time.now)
    self.class.schedule_job
  end

  def error(job, exception)
    ScheduledJob.logger.warn("DelayedJob error: Job: #{job.id}, in queue #{self.class.queue_name}, exception: #{exception}")
    self.class.schedule_job
  end

  module ScheduledJobClassMethods
    # This method should be called when scheduling a recurring job as it checks to ensure no
    # other instances of the job are already running.
    def schedule_job(job = nil)
      unless job_exists?(job)
        callback = ScheduledJob.config.fast_mode
        in_fast_mode = callback ? callback.call(self) : false

        run_at = in_fast_mode ? Time.now.utc + 1 : time_to_recur(Time.now.utc)

        Delayed::Job.enqueue(new, :run_at => run_at, :queue => queue_name)
      end
    end

    def queue_name
      "Default"
    end

    def random_minutes(base, random_delta)
      random_delta *= -1 if random_delta < 0
      (base + Random.new.rand((-1 * random_delta)..random_delta)).minutes
    end

    def job_exists?(job = nil)
      conditions = ['(handler like ? OR handler like ?) AND failed_at IS NULL', "%:#{self.name} %", "%:#{self.name}\n%"]
      unless job.blank?
        conditions[0] << " AND id != ?"
        conditions << job.id
      end
      Delayed::Job.exists?(conditions)
    end

    def run_duration_threshold
      self.const_defined?(:RUN_DURATION_THRESHOLD) ? self::RUN_DURATION_THRESHOLD : nil
    end
  end
end

require 'rake'

module ScheduledJob
  class Job
    include Rake::DSL if defined? Rake::DSL

    def install_tasks
      def check_schedule_job(job)
        if job.respond_to?(:time_to_recur)
          job.schedule_job
        else
          job.descendants.each { |j| check_schedule_job(j) }
        end
      end

      namespace:jobs do
        desc "Will schedule all scheduled jobs"
        task :reschedule => :environment do
          ScheduledJob.classes.each do |job|
            check_schedule_job(job)
          end
        end
      end
    end
  end
end

ScheduledJob::Job.new.install_tasks

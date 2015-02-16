require 'rake'

module ScheduledJob
  class Job
    include Rake::DSL if defined? Rake::DSL

    def install_tasks
      namespace:jobs do
        desc "Will schedule all scheduled jobs"
        task :reschedule => :environment do
          ScheduledJob.reschedule
        end
      end
    end
  end
end

ScheduledJob::Job.new.install_tasks

require 'rake'

module ScheduledJob
  class Job
    include Rake::DSL if defined? Rake::DSL

    def install_tasks
      namespace:jobs do
        desc "Will schedule all scheduled jobs"
        task :reschedule => :environment do
          if ActiveRecord::Base.connection.table_exists?('delayed_jobs')
            ScheduledJob.reschedule
          else
            puts "Skipping this rake task as the delayed_jobs table doesn't exist yet."
          end
        end
      end
    end
  end
end

ScheduledJob::Job.new.install_tasks

# 0.0.2
Initial public release

# 0.0.3
Removing hard coded Delayed Job dependencies

# 0.0.4
Adds one second back off to the fast mode

# 0.0.5
Removed the compulsory .configure call

# 0.0.7
Fixes substring job lookup bug

# 0.0.8
Bug fix for multiple scheduling potential

# 0.0.9
Adds local db for development

# 0.1.0
Makes available the `rake jobs:reschedule` rake task
Adds a config to allow the scheduling for more than one instance of the same job

# 0.1.1
Allows jobs in config to be strings, symbols, or classes. If a string or symbol is provided, it will be resolved to a constant before scheduling the job.

# 0.1.2
Falls back to the Delayed Job default queue name if none is provided. Ensures that the run at is set using UTC timezone. Updates specs to run on the latest ruby version on CI.

# 0.1.3
Gracefully handle the case when the delayed_job table doesn't exist but `rake jobs:reschedule` is called.
This is needed is some cases where scheduled_job is deployed in a container and the container needs to start so the table can be created.

# 0.2.3
Updating the acitve* gem dependency versions to support the current release. Also drops travis testing for ruby 1.9.3 which is no longer an officially supported Ruby version.

# 0.2.4
Updates the way that we detect if an instance of a job has already been scheduled. This was because we were incorrectly seeing a delayed method as an instance of that job already being scheduled.

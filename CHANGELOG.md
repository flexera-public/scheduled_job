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

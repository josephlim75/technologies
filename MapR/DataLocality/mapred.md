## Mapper Tasks and Data Locality

You can make use of the parameter `mapped.fairscheduler.locality.delay` in `mapred-site.xml` to achieve that. This parameter identifies how long the jobtracker should wait before scheduling a non-local task. This value is set in milliseconds.

For example, If you set the value to 60 seconds, jobtracker will wait for 60 seconds to figure out local data nodes and will try to execute tasks on those local nodes and if it fails to find local nodes in 60 seconds, tasks are executed on non-local nodes.

The value for this parameter varies from environment to environment and you would need to identify this after some benchmarking tests.
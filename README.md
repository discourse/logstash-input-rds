# Logstash Input Multi-RDS

RDS Postgres instances do not support cloudwatch, logs must be polled using the AWS API. This logstash input plugin polls RDS logs at a configured interval with support for multiple instances of logstash and multiple RDS databases (thus the name: multirds). Locking and marker tracking are done with DynamoDB. 

The plugin will automatically create a DynamoDB table, but if you want to do it manually, the name must match the configured `group_name` and the primary key is `id`.

## Special thanks

* This is a fork of logstash input RDS (https://github.com/discourse/logstash-input-rds) though I think I made too many changes to ever merge it back in
* Using DynamoDB for locking and marker tracking was stolen from the Kinesis input plugin (https://github.com/logstash-plugins/logstash-input-kinesis) (which we're also using for Cloudwatch logs) 
* The lock code was taken from the Dynalock gem (https://github.com/tourlane/dynalock) which works fine, but I needed to store extra data on the lock record so I just copied their code

## Configuration

```
    input {
      multirds {
        region => "us-east-1"
        instance_name_pattern => ".*"
        log_file_name_pattern => ".*"
        group_name => "rds"

      }
    }
```

* `region`: The AWS region for RDS. The AWS SDK reads this info from the usual places, so it's not required, but if you don't set it somewhere the plugin won't run
  * **required**: false

* `instance_name_pattern`: A regex pattern of RDS instances from which logs will be consumed
  * **required**: false
  * **default value**: `.*`

* `log_file_name_pattern`: A regex pattern of RDS log files to consume
  * **required**: false
  * **default value**: `.*`

* `group_name`: A unique identifier for all the instances of logstash which will be consuming this instance and log file pattern. Used for the lock table name.
  * **required**: true

* `client_id`: A unique identifier for a particular instance of logstash in the cluster
  * **required**: false
  * **default value**: `<hostname>:<uuid>`

* `polling_frequency`: The frequency in seconds at which RDS is polled for new log events.
  * **required**: false
  * **default value**: `600`

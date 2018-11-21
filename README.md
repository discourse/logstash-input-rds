# Logstash Input Multi-RDS

Forked from discourse/logstash-input-rds I needed competing consumer and multi-db support 
    input {
      rds {
        region => "us-west-2"
        instance_name => "development"
        log_file_name => "error/postgresql.log"
      }
    }

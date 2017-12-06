# Logstash Input RDS

    input {
      rds {
        region => "us-west-2"
        instance_name => "development"
        log_file_name => "error/postgresql.log"
      }
    }


# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "logstash/inputs/rds/patch"
require "time"

Aws.eager_autoload!

class LogStash::Inputs::Rds < LogStash::Inputs::Base
  include LogStash::PluginMixins::AwsConfig::V2

  config_name "rds"
  milestone 1
  default :codec, "plain"

  config :instance_identifier, :validate => :string, :required => true
  config :log_file_name, :validate => :string, :required => true
  config :polling_frequency, :validate => :number, :default => 600

  def register
    require "aws-sdk"
    @logger.info "Registering RDS input", :instance_identifier => @instance_identifier
    @database = Aws::RDS::DBInstance.new @instance_identifier, aws_options_hash
    @sincedate = filename2datetime "1999-01-01-01" # FIXME sincedb
  end

  def run(queue)
    Stud.interval(@polling_frequency) do
      @logger.info "finding files starting #{@sincedate} (#{@sincedate.to_i * 1000})"

      logfiles = @database.log_files({
        filename_contains: @log_file_name,
        file_last_written: @sincedate.to_i * 1000,
      })
      logfiles.each do |logfile|
        @sincedate = filename2datetime logfile.name

        more = true
        marker = "0"
        while more do
          response = logfile.download({marker: marker})
          response[:log_file_data].lines.each do |line|
            @codec.decode(line) do |event|
              event.set "rds-instance", @instance_identifier
              event.set "log-file", @log_file_name
              queue << event
            end
          end
          more = response[:additional_data_pending]
          marker = response[:marker]
        end
      end
    end
  end

  def filename2datetime(name)
    fragments = name.match /(\d{4})-(\d{2})-(\d{2})-(\d{2})$/
    Time.parse "#{fragments[1]}-#{fragments[2]}-#{fragments[3]} #{fragments[4]}"
  end
end


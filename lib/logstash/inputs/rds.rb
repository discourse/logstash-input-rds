# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "aws-sdk"
require "logstash/inputs/rds/patch"
require "logstash/plugin_mixins/aws_config"
require "time"

Aws.eager_autoload!

class LogStash::Inputs::Rds < LogStash::Inputs::Base
  include LogStash::PluginMixins::AwsConfig::V2

  config_name "rds"
  milestone 1
  default :codec, "plain"

  config :instance_name, :validate => :string, :required => true
  config :log_file_name, :validate => :string, :required => true
  config :polling_frequency, :validate => :number, :default => 600
  config :sincedb_path, :validate => :string, :default => nil
  config :number_of_lines, :validate => :number, :default => 10000

  def register
    @logger.info "Registering RDS input", :region => @region, :instance => @instance_name, :log_file => @log_file_name, :number_of_lines => @number_of_lines
    @database = Aws::RDS::DBInstance.new @instance_name, aws_options_hash

    path = @sincedb_path || File.join(ENV["HOME"], ".sincedb_" + Digest::MD5.hexdigest("#{@instance_name}+#{@log_file_name}"))
    @sincedb = SinceDB::File.new path
  end

  def run(queue)
    @thread = Thread.current
    Stud.interval(@polling_frequency) do
      @logger.debug "finding #{@log_file_name} for #{@instance_name} starting #{@sincedb.read} (#{@sincedb.read.to_i * 1000})"
      begin
        logfiles = @database.log_files({
          filename_contains: @log_file_name,
          file_last_written: @sincedb.read.to_i * 1000,
        })
        logfiles.each do |logfile|
          @logger.debug "downloading #{logfile.name} for #{@instance_name}"
          more = true
          marker = "0"
          while more do
            response = logfile.download({marker: marker, number_of_lines: @number_of_lines})
            response[:log_file_data].lines.each do |line|
              @codec.decode(line) do |event|
                decorate event
                event.set "rds_instance", @instance_name
                event.set "log_file", @log_file_name
                queue << event
              end
            end
            more = response[:additional_data_pending]
            marker = response[:marker]
          end
          @sincedb.write (filename2datetime logfile.name)
        end
      rescue Aws::RDS::Errors::ServiceError
        # the next iteration will resume at the same location
        @logger.warn "caught AWS service error"
      end
    end
  end

  def stop
    Stud.stop! @thread
  end

  def filename2datetime(name)
    parts = name.match /(\d{4})-(\d{2})-(\d{2})-(\d{2})$/
    Time.utc parts[1], parts[2], parts[3], parts[4]
  end

  private
  module SinceDB
    class File
      def initialize(file)
        @db = file
      end

      def read
        if ::File.exists?(@db)
          content = ::File.read(@db).chomp.strip
          return content.empty? ? Time.new : Time.parse(content)
        else
          return Time.new("1999-01-01")
        end
      end

      def write(time)
        ::File.open(@db, 'w') { |file| file.write time.to_s }
      end
    end
  end
end

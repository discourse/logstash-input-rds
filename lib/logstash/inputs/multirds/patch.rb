require 'aws-sdk'

begin
  old_stderr = $stderr
  $stderr = StringIO.new

  module Aws
    const_set(:RDS, Aws::RDS)
  end
ensure
  $stderr = old_stderr
end

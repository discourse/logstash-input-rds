Gem::Specification.new do |s|
  s.name          = 'logstash-input-rds'
  s.version       = '0.17.0'
  s.summary       = 'Ingest RDS log files to Logstash'

  s.authors       = ['Andrew Schleifer']
  s.email         = ['me@andrewschleifer.name']
  s.homepage      = 'https://github.com/discourse/logstash-input-rds'

  s.require_paths = ['lib']
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { 'logstash_plugin' => 'true', 'logstash_group' => 'input' }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core-plugin-api', '~> 2.0'
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'logstash-mixin-aws'
  s.add_runtime_dependency 'stud', '>= 0.0.22'
  s.add_development_dependency 'logstash-devutils', '>= 0.0.16'
end

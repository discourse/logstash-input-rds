require "logstash/devutils/rake"

task :build do
	sh "gem build logstash-input-rds"
end

task :clean do
	sh "rm *.gem"
end

task :push do
	sh "git push && git push --tags"
end

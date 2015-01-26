require 'rubygems'
require 'rubygems/command'
require 'rubygems/dependency_installer'

begin
  Gem::Command.build_args = ARGV
rescue NoMethodError
end

inst = Gem::DependencyInstaller.new
if RUBY_PLATFORM == 'java'
  inst.install 'jdbc-sqlite3'
else
  inst.install 'sqlite3', '~> 1'
end

# create dummy rakefile to indicate success
File.open(File.join(File.dirname(__FILE__), 'Rakefile'), 'w') do |f|
  f.puts('task :default')
end

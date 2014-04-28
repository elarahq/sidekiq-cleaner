require "bundler/gem_tasks"
require 'rspec/core/rake_task'

$:.unshift('lib')

RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/unit/*.rb"
end

task :default => :spec
task :test    => :spec

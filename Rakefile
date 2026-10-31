require "bridgetown"

Bridgetown.load_tasks

task default: :build

desc "Build the site for deployment"
task build: :clean do
  Bridgetown::Commands::Build.start
end

desc "Remove the generated site"
task :clean do
  Bridgetown::Commands::Clean.start
end

desc "Run the checks' own tests"
task :test do
  ruby "-e", 'Dir["test/**/*_test.rb"].each { |file| require File.expand_path(file) }'
end

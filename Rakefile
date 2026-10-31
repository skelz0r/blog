require "bridgetown"

Bridgetown.load_tasks

task default: :build

desc "Build the site for deployment"
task build: :clean do
  ENV["BRIDGETOWN_ENV"] ||= "production"
  Bridgetown::Commands::Build.start
end

desc "Build the site then check links, images and alt texts"
task check: %i[build proof]

desc "Check links, images and alt texts of the already built site"
task :proof do
  require_relative "lib/link_check"
  LinkCheck.run("output", external: ENV["SKIP_EXTERNAL_LINKS"].to_s.empty?)
end

desc "Remove the generated site"
task :clean do
  Bridgetown::Commands::Clean.start
end

desc "Run the checks' own tests"
task :test do
  ruby "-e", 'Dir["test/**/*_test.rb"].each { |file| require File.expand_path(file) }'
end

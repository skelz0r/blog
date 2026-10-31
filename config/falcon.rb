#!/usr/bin/env falcon-host
# frozen_string_literal: true

require "falcon/environment/rack"

service "blog" do
  include Falcon::Environment::Rack

  rackup_path File.expand_path("config.ru", Pathname.new(root).join(".."))
  port ENV.fetch("BRIDGETOWN_PORT") { 4000 }

  endpoint do
    Async::HTTP::Endpoint.parse("http://localhost", port: port)
  end
end

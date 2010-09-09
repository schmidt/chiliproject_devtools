

# Sample configuration file for Unicorn (not Rack)
worker_processes 1
listen 3000

# feel free to point this anywhere accessible on the filesystem
pid File.expand_path("../unicorn.pid", __FILE__)
stdout_path File.expand_path("../unicorn.log", __FILE__)
stderr_path File.expand_path("../unicorn.log", __FILE__)

GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

before_fork do |server, worker|
  # this is the important part.
  # place all your 'stable' code here, for example rubygems, the ruby stdlib
  # maybe even parts of your application. Since it's preloaded, it doesn't
  # need to be reloaded when unicorn receives a HUP
  require 'active_support'
end



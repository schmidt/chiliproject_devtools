gem 'ffaker'
gem 'populator'
gem 'rack-contrib'
gem 'ruby-prof'
gem 'rcov'
gem 'rspec', '~> 1.3.0'
gem 'rspec-rails'
gem 'directory_watcher'
gem 'unicorn'
# Adding stronger dependency to kgio 2.2 since 2.3.2 does not install on our ci
# server.  Whenever unicorn is removed, this dependency may also be removed.
gem 'kgio', '~> 2.2.0'
gem "factory_girl",     "~> 1.2.4"

group :development, :test do
  # remove once linecache 0.46 is released
  gem "require_relative"
  gem "ruby-debug"
end


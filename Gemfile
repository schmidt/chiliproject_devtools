gem 'ffaker'
gem 'populator'
gem 'rack-contrib'
gem 'ruby-prof'
gem 'rspec', '~> 1.3.0'
gem 'rspec-rails'
gem 'directory_watcher'
gem 'unicorn'
# Adding stronger dependency to kgio 2.2 since 2.3.2 does not install on our ci
# server.  Whenever unicorn is removed, this dependency may also be removed.
gem 'kgio', '~> 2.2.0'
gem "factory_girl",     "~> 1.2.4"

gem 'rcov', :platforms => :mri_18

group :development, :test do
  gem "ruby-debug",   :platforms => :mri_18
  gem "ruby-debug19", :platforms => :mri_19
end


ln_sf 'vendor/plugins/dev_tools/root_gemfile.rb', 'Gemfile'

begin
  require 'rubygems'
  require 'bundler'
  Bundler.setup
rescue LoadError
  puts <<-EOS
    \033[0;31m\033[5m#############################\033[0m
    \033[0;31m\033[5m#\033[0m       Hey, yo, you!       \033[0;31m\033[5m#\033[0m
    \033[0;31m\033[5m#\033[0m   `\033[1;33mgem install bundler\033[0m`   \033[0;31m\033[5m#\033[0m
    \033[0;31m\033[5m#############################\033[0m
  EOS
end

namespace :dev do
  task :prepare_setup do
    ENV['REDMINE_LANG'] ||= 'en'
    ENV['VERBOSE'] ||= '0'
    begin
      Rake::Task["db:drop:all"].invoke      
    rescue Exception => e
    end
    Rake::Task["db:create:all"].invoke
  end

  task :bundler

  desc "does all database tasks necessary for a clean redmine install"
  task :setup => %w[
    generate_session_store prepare_setup
    db:migrate redmine:load_default_data
    db:migrate:plugins db:schema:dump db:test:prepare
  ]
end

ln_sf File.expand_path('../../root_gemfile.rb', __FILE__), 'Gemfile'

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

  desc 'Dieser nette Rake Task ist extra für den lieben Tim, damit er was zum spielen hat. Viel Spaß.'
  task :bundler do
    puts 'Danke, dass Sie sich für Bundler entschieden haben.'
  end

  desc "does all database tasks necessary for a clean redmine install"
  task :setup => %w[generate_session_store prepare_setup] do
    p "Moving redmine plugins away, in case they break migrations"
    Dir["vendor/plugins/redmine_*"].each do |f|
      FileUtils.mv(f, f.sub("plugins/", "schmugins_"))
    end
    Rake::Task["db:migrate"].invoke
    p "Moving redmine plugins back"
    Dir["vendor/schmugins_*"].each do |f|
      FileUtils.mv(f, f.sub("schmugins_", "plugins/"))
    end
    %w[redmine:load_default_data
      db:migrate:plugins db:schema:dump
      db:test:prepare
    ].each {|t| Rake::Task[t].invoke }
  end

end

begin
  require 'rubygems'
  require 'bundler'
  begin
    Bundler.setup
  rescue Bundler::GemfileNotFound
      puts <<-EOS
        \033[0;31m\033[5m#############################\033[0m
        \033[0;31m\033[5m#\033[0m    You need a Gemfile!    \033[0;31m\033[5m#\033[0m
        \033[0;31m\033[5m#\033[0m`\033[1;33mrake dev:download_gemfile\033[0m`\033[0;31m\033[5m#\033[0m
        \033[0;31m\033[5m#############################\033[0m
      EOS
  end
rescue LoadError
  if $!.message == 'no such file to load -- bundler'
    puts <<-EOS
      \033[0;31m\033[5m#############################\033[0m
      \033[0;31m\033[5m#\033[0m       Hey, yo, you!       \033[0;31m\033[5m#\033[0m
      \033[0;31m\033[5m#\033[0m   `\033[1;33mgem install bundler\033[0m`   \033[0;31m\033[5m#\033[0m
      \033[0;31m\033[5m#############################\033[0m
    EOS
    exit 1
  else
    raise
  end
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

  task :download_gemfile do
    require 'lib/redmine/version'
    ENV['URL'] ||= if Redmine::VERSION::MAJOR == 0
      'https://github.com/finnlabs/chiliproject-gemfile/raw/0-9-stable/Gemfile'
    else
      'https://github.com/finnlabs/chiliproject-gemfile/raw/master/Gemfile'
    end
    `wget --no-check-cert #{ENV['URL']} -O Gemfile`
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
    post_setup = %w[redmine:load_default_data
      db:migrate:plugins db:schema:dump
    ]
    sh "bundle exec rake #{post_setup.join(' ')} --trace"
    begin
      Rake::Task["db:test:prepare"].invoke
    rescue
      puts <<-EOS
        \033[0;31m\033[5m####################################################\033[0m
        \033[0;31m\033[5m#   Something went wrong during db:test:prepare.   #\033[0m
        \033[0;31m\033[5m#    This is not fatal for deployment, but you     #\033[0m
        \033[0;31m\033[5m#         won't be able to run the tests.          #\033[0m
        \033[0;31m\033[5m####################################################\033[0m
      EOS
    end
  end

end

namespace :dev do
  task :prepare_setup do
    ENV['REDMINE_LANG'] ||= 'en'
    ENV['VERBOSE'] ||= '0'
    Rake::Task["db:drop:all"].invoke
    Rake::Task["db:create:all"].invoke
  end
  desc "does all database tasks necessary for a clean redmine install"

  task :setup => %w[
    generate_session_store prepare_setup
    db:migrate redmine:load_default_data
    db:migrate:plugins db:schema:dump db:test:prepare
  ]
end

namespace :dev do
  task :prepare_setup do
    ENV['REDMINE_LANG'] ||= 'en'
    ENV['VERBOSE'] ||= '0'
  end
  desc "does all database tasks necessary for a clean redmine install"
  
  task :setup => %w[
    generate_session_store prepare_setup
    db:drop:all db:create:all db:migrate
    redmine:load_default_data populate:all
    db:migrate:plugins db:schema:dump db:test:prepare
  ]
end

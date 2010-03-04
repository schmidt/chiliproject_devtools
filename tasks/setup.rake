namespace :dev do
  task :prepare_setup do
    ENV['REDMINE_LANG'] ||= 'en'
    warn "skipped dev:populate:all"
  end
  desc "does all database tasks necessary for a clean redmine install"
  
  task :setup => %w[
    prepare_setup
    gems:build gems:install db:drop
    db:create:all db:migrate
    redmine:load_default_data
    db:migrate_plugins db:schema:dump db:test:prepare
    populate:all
  ]
end

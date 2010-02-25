namespace :dev do
  task :setup => %w[
    gems:build gems:install
    db:drop:all db:create:all db:migrate db:migrate_plugins db:schema:dump db:test:prepare
    redmine:load_default_data populate:all
  ]
end

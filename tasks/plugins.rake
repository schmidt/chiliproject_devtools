$LOAD_PATH.unshift(File.expand_path(File.join(__FILE__, "..", "..", "lib")))
require 'dev_helper'

namespace :dev do
  namespace :plugins do
    include DevHelper

    desc "Lists available plugins"
    task :list do
      puts Dir.glob("#{cockpit_svn_root}*").select{|f| File.directory? f }.collect do |p| 
        File.basename(p)
      end.join(", ")
    end
    
    desc "Include plugins in the current redmine"
    task :enable, :plugins do |t, args|
      plugins = args.plugins || []
      plugins = plugins.split(" ").flatten
      enable_finn_plugins(plugins)
      Rake::Task["db:migrate:plugins"].invoke
      Rake::Task["db:schema:dump"].invoke
      Rake::Task["db:test:prepare"].invoke
    end
    
    desc "Remove plugins from the current redmine"
    task :disable, :plugins do |t, args|
      plugins = args.plugins || []
      plugins = plugins.split(" ").flatten
      disable_finn_plugins :only => plugins
    end
    
    desc "Prepare a plugin for cindy"
    task :prepare_cruise, :plugin do |t, args|
      plugin = args.plugin
      if plugin
        tasks_path = File.join cockpit_svn_root, plugin, "tasks"
        FileUtils.mkdir_p tasks_path
        File.open File.join(tasks_path, "cruise.yml"), 'w' do |f|
          f << "
--- 
:unit_tests: 
  :required_plugins:
  - dev_tools
  - redmine_cucumber
  :tasks:
  - test:plugins:#{plugin}
  - spec:plugins:#{plugin}
:integration_sets: 
  :telekom: 
  - :redmine_picockpit_privacy
  - :redmine_costs
  :siemens: 
  - :redmine_siemens_customizing
  - :redmine_costs"  
        end
        File.open File.join(tasks_path, "cruise.rake"), 'a' do |f|
          f << "
require 'yaml'

namespace :#{plugin} do
  include DevHelper
  
  def config
    YAML.load_file File.expand_path(File.join(__FILE__, '..', 'cruise.yml'))
  end
  
  desc 'Run unit tests for #{plugin}'
  task :'cruise:unit' do
    run_unit_tests('#{plugin}')
  end
  
  desc 'Run integration tests for #{plugin}'
  task :'cruise:integration' do
    run_integration_tests('#{plugin}')
  end
  
  desc 'Run cruise task for #{plugin}'
  task :cruise do
    run_cruise_task('#{plugin}')
  end
  
  task :'cruise:unit:internal' do
    unit_tests('redmine_picockpit_privacy')
  end
  
  task :'cruise:integration:internal' do
    integration_tests('redmine_picockpit_privacy')
  end
end
"
        end
      end
    end
  end
end

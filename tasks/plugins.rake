require 'pathname'

namespace :dev do
  namespace :plugins do

    def cockpit_svn_root
      dev_tools = File.expand_path(File.join(__FILE__, "..", "..")) # Get dev_tools dir
      f = File.readlink(dev_tools) if FileTest.symlink?(dev_tools) and File.directory?(dev_tools)
      f = File.expand_path(File.join(dev_tools, "..", f)) if Pathname.new(f).relative?
      File.expand_path(File.join(f, "..")) + File::SEPARATOR
    end
    
    desc "Lists available plugins"
    task :list do
      puts Dir.glob("#{cockpit_svn_root}*").select{|f|File.directory? f}.collect do |p| 
        File.basename(p)
      end.join(", ")
    end
    
    desc "Include plugins in the current redmine"
    task :enable, :plugins do |t, args|
      plugins = args.plugins || []
      plugins = plugins.split(" ")
      plugins.each do |p|
        plugin_path = File.expand_path(File.join(RAILS_ROOT, "vendor", "plugins", p))
        unless File.exist? plugin_path
          system "ln -s #{File.join(cockpit_svn_root, p)} #{plugin_path}"
        end
      end
      Rake::Task["db:migrate:plugins"].invoke
      Rake::Task["db:schema:dump"].invoke
      Rake::Task["db:test:prepare"].invoke
    end
    
    desc "Remove plugins from the current redmine"
    task :disable, :plugins do |t, args|
      plugins = args.plugins || []
      plugins = plugins.split(" ")
      plugins.each do |p|
        system "rm #{File.expand_path(File.join(RAILS_ROOT, "vendor", "plugins", p))}"
      end
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
  def reset_db
    Rake::Task['dev:setup'].invoke
  end
  
  desc 'Run unit tests for #{plugin}'
  task :'cruise:unit' do
    config = YAML.load_file File.expand_path(File.join(__FILE__, '..', 'cruise.yml'))
    config[:unit_tests].each do |t|
      reset_db
      Rake::Task[t.to_sym].invoke
    end
  end
  
  desc 'Run integration tests for #{plugin}'
  task :'cruise:integration' do
    config = YAML.load_file File.expand_path(File.join(__FILE__, '..', 'cruise.yml'))    
    config[:integration_sets].keys.each do |iset|
      puts \"Running integration tests for #{plugin} in \#{iset} environment\"
      config[:integration_sets][iset].each do |t|
        Rake::Task[:'dev:plugins:enable'].invoke(t.to_s)
      end
      
      # Run unit tests again in integrated environment
      reset_db
      Rake::Task[:'#{plugin}:cruise:unit'].invoke
      
      # For each other plugin, run unit tests, if possible
      config[:integration_sets][iset].each do |t|
        if (nt = Rake::Task[:'#{plugin}:cruise:unit'])
          reset_db
          nt.invoke
        else
          if (nt = Rake::Task[:\"test:plugins:\#{t}\"])
            reset_db
            nt.invoke
          end
          if (nt = Rake::Task[:\"spec:plugins:\#{t}\"])
            reset_db
            nt.invoke
          end
        end
      end
      
      Rake::Task[:cucumber].invoke
      
      config[:integration_sets][iset].each do |t|
        Rake::Task[:'dev:plugins:disable'].invoke(t.to_s)
      end
    end
  end
  
  desc 'Run cruise task for #{plugin}'
  task :cruise => [:'cruise:unit', :'cruise:integration']
end
"
        end
      end
    end
  end
end

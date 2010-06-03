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
    
    desc "Includes a plugin in the current redmine"
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
    
    desc "Remove a plugin in the current redmine"
    task :disable, :plugins do |t, args|
      plugins = args.plugins || []
      plugins = plugins.split(" ")
      plugins.each do |p|
        system "rm #{File.expand_path(File.join(RAILS_ROOT, "vendor", "plugins", p))}"
      end
    end
  end
end

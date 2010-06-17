# This module provides various helper methods for the continuous integration system, 
# like (de-)activating plugins, setting up the DB and running different test configurations
module DevHelper
  
  def cockpit_svn_root
    dev_tools = File.expand_path(File.join(__FILE__, "..", "..")) # Get dev_tools dir
    f = File.readlink(dev_tools) if FileTest.symlink?(dev_tools) and File.directory?(dev_tools)
    f = File.expand_path(File.join(dev_tools, "..", f)) if Pathname.new(f).relative?
    File.expand_path(File.join(f, "..")) + File::SEPARATOR
  end

  def plugin_root
    File.expand_path File.join(RAILS_ROOT, "vendor", "plugins")
  end
  
  def run_unit_tests(plugin)
    config[:unit_tests][:tasks].each do |t|
      system_rake 'dev:setup'
      Rake::Task[t.to_sym].invoke
    end
  end
  
  def run_integration_tests(plugin)
    config[:integration_sets].keys.each do |iset|
      puts "Running integration tests for #{plugin} in #{iset} environment"
      
      config[:unit_tests][:required_plugins] ||= []
      disable_finn_plugins :except => (config[:unit_tests][:required_plugins] + [plugin])
      reset_db
      
      config[:integration_sets][iset].each do |t|
        Rake::Task[:'dev:plugins:enable'].invoke(t.to_s)
      end
      
      # Run unit tests again in integrated environment
      Rake::Task[:"#{plugin}:cruise:unit"].invoke
      
      # For each other plugin, run unit tests, if possible
      config[:integration_sets][iset].each do |t|
        if (nt = Rake::Task[:"#{plugin}:cruise:unit"])
          reset_db
          nt.invoke
        else
          if (nt = Rake::Task[:"test:plugins:#{t}"])
            reset_db
            nt.invoke
          end
          if (nt = Rake::Task[:"spec:plugins:#{t}"])
            reset_db
            nt.invoke
          end
        end
      end
      
      system_rake "cucumber:html"
      
      config[:integration_sets][iset].each do |t|
        Rake::Task[:'dev:plugins:disable'].invoke(t.to_s)
      end
    end
  end
  
  def run_cruise_task_in_testing_env(plugin)
    p "rake #{plugin}:cruise:unit"
    system_rake "#{plugin}:cruise:unit"
    p "rake #{plugin}:cruise:integration"
    system_rake "#{plugin}:cruise:integration"
    disable_finn_plugins :except => ([plugin])
  end
  
  def run_cruise_task(plugin)
    ENV['RAILS_ENV'] = 'test'
    plugs = (config[:unit_tests][:required_plugins] || []) + [plugin]    
    disable_finn_plugins :except => plugs
    enable_finn_plugins plugs
    Rake::Task[:'dev:setup'].invoke
    system_rake "#{plugin}:cruise_testing"
  end

  def reset_db
    ENV['REDMINE_LANG'] = 'en'
    ENV['VERBOSE'] = '0'
    begin
      Rake::Task["db:drop"].invoke      
    rescue Exception => e
    end
    Rake::Task["db:create"].invoke
    %w(generate_session_store db:migrate redmine:load_default_data
    db:migrate:plugins db:schema:dump db:test:prepare).each do |t|
      Rake::Task[t.to_sym].invoke
    end
  end
  
  def system_rake(task)
    system "rake #{task} --trace"
  end

  def active_plugins
    Dir.glob(File.expand_path(File.join(plugin_root, "*"))).select do |f| 
      File.symlink?(f) && File.exists?(File.join(cockpit_svn_root, File.basename(f)))
    end
  end
  
  # Remove all Finn plugin symlinks from vendor, except for dev_tools and anything 
  # passed in as except list 
  def disable_finn_plugins(options = {})
    options[:except] = (["dev_tools", "redmine_cucumber"] << options[:except]).flatten.compact
    unless options[:only].nil?
      only = options[:only].collect {|p| File.join(plugin_root, p)}
    else
      only = nil
    end
    (only || active_plugins).each do |f|
      FileUtils.rm(f) unless options[:except].include?(File.basename(f))
    end
  end

  def enable_finn_plugins(plugins = [])
    (plugins - (active_plugins.collect{|f| File.basename f})).each do |p|
      FileUtils.ln_s(File.join(cockpit_svn_root, p), File.join(plugin_root, p))
    end
  end
end
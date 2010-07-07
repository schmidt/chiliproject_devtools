begin
  require 'ci/reporter/rake/rspec'     # use this if you're using RSpec  
  require 'ci/reporter/rake/test_unit' # use this if you're using Test::Unit
rescue LoadError
  puts ("Missing the CI Reporter gem. Install timfel-ci_reporter or " +
    "you won't get XML output for the CI")
end

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
  
  def invoke_ci_reporter
    begin
      yield
    rescue RuntimeError => e
      puts "CI Reporter disabled"
    end
  end
  
  ['unit', 'integration'].each do |t|
    define_method(:"run_#{t}_tests") do |plugin|
      run_cruise_task(plugin, t)
    end
  end
  
  def unit_tests(plugin)
    return if config[:unit_tests][:tasks].nil?
    invoke_ci_reporter do
      Rake::Task["ci:setup:testunit"].invoke
      Rake::Task["ci:setup:rspec"].invoke
    end
    config[:unit_tests][:tasks].each do |t|
      reset_db
      Rake::Task[t.to_sym].invoke
    end
  end
  
  def integration_tests(plugin)
    return unless config.has_key? :integration_sets
    if config[:integration_sets].nil?      
      FileUtils.rm Dir.glob("#{RAILS_ROOT}/features/reports/*")
      Rake::Task["cucumber:ci"].invoke
    end
    
    invoke_ci_reporter do
      Rake::Task["ci:setup:testunit"].invoke
      Rake::Task["ci:setup:rspec"].invoke
    end
    
    config[:integration_sets].keys.each do |iset|
      puts "Running integration tests for #{plugin} in #{iset} environment"
      
      config[:unit_tests][:required_plugins] ||= []
      disable_finn_plugins :except => (config[:unit_tests][:required_plugins] + [plugin])
      enable_finn_plugins(config[:integration_sets][iset] || [])
      
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
            
      Rake::Task["cucumber:ci"].invoke
      
      config[:integration_sets][iset].each do |t|
        next if t.to_s == plugin.to_s
        Rake::Task[:'dev:plugins:disable'].invoke(t.to_s)
      end
    end
  end
  
  def run_cruise_task(plugin, *args)
    args = ['unit', 'integration'] if args.empty?    
    ENV['RAILS_ENV'] = 'test'
    cruise_task_prepare(plugin)
    args.each do |task|
      system_rake "#{plugin}:cruise:#{task}:internal"
    end
    cruise_task_clean(plugin)
  end
  
  def cruise_task_prepare(plugin)
    plugs = (config[:unit_tests][:required_plugins] || []) + [plugin]
    disable_finn_plugins :except => plugs
    enable_finn_plugins plugs
  end
  
  def cruise_task_clean(plugin)
    disable_finn_plugins :except => ([plugin])
  end

  def reset_db
    Rake::Task["db:test:clone_structure"].invoke
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
    (plugins.collect(&:to_s) - (active_plugins.collect{|f| File.basename f})).each do |p|
      FileUtils.ln_s(File.join(cockpit_svn_root, p), File.join(plugin_root, p))
    end
  end
end
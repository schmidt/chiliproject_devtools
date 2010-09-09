namespace :dev do
  # desc 'updates reloader'
  #   task :update_reloader do
  #     branch = ENV['BRANCH'] || 'pluggable_reloader'
  #     %w[active_support/core_ext/module/anonymous.rb
  #       active_support/dependencies.rb
  #       active_support/core_ext/kernel/singleton_class.rb].each do |file|
  #       target = File.expand_path("../../lib/#{file}", __FILE__)
  #       mkdir_p File.dirname(target)
  #       sh "curl http://github.com/rkh/rails/raw/#{branch}/activesupport/lib/#{file} -o #{target}"
  #     end
  #     mv \
  #       File.expand_path("../../lib/active_support/dependencies.rb", __FILE__),
  #       File.expand_path("../../lib/fixed_dependencies.rb", __FILE__)
  #   end
  desc 'updates reloader'
  task :update_reloader do
    sh "curl " \
    "http://github.com/rails/rails/raw/2-3-stable/activesupport/lib/active_support/dependencies.rb " \
    "-o #{File.expand_path("../../lib/fixed_dependencies.rb", __FILE__)}"
  end

  desc 'runs via unicorn'
  task :magical_reloading_sparkles do
    # Copyright (c) 2010 Jonathan Stott.
    # Released under the terms of the MIT License
    require 'directory_watcher'
    require 'directory_watcher/rev_scanner'

    # deactivate the reloader, if necessary
    reloader_active = lambda do |activate|
      devrb = File.join(Rails.root, "config/environments/development.rb")
      file = File.read(devrb).gsub(/^(config.cache_classes\s*=\s*)#{activate.to_s}/, "\\1#{(!activate).to_s}")
      $reloader_was_deactivated = true if File.read(devrb) != file
      File.open(devrb, 'w') do |f|
        f.truncate(0)
        f.write(file)
      end
    end
    reloader_active[false]

    LOGFILE = File.expand_path("../../lib/unicorn.log", __FILE__) # unicorn's log file
    PIDFILE = File.expand_path("../../lib/unicorn.pid", __FILE__) # unicorn's pid file
    GLOB = ['**/*.rb', '**/*.rhtml'] # glob of the application's files

    # remove the old log
    system "rm -f -- #{LOGFILE}"

    # start the unicorn
    system "unicorn_rails --daemonize -c #{File.expand_path("../../lib/unicorn.config.dev.rb", __FILE__)}"

    # get the pid
    pid = File.open(PIDFILE) { |f| f.read }.chomp.to_i

    # open a watcher to read the log as it changes
    log_watch = DirectoryWatcher.new File.dirname(LOGFILE),
    :glob => File.basename(LOGFILE),
    :scanner => :rev,
    :pre_load => true

    # open the logfile
    log = File.open(LOGFILE)

    # add an observer to read it
    log_watch.add_observer do |*args|
      $stdout.puts log.read
    end


    # watch our plugins for changes
    dws = Dir.glob(File.join(Rails.root, "vendor/plugins/*")).inject([]) do |ary, dir|
      if FileTest.symlink?(dir) and File.directory?(dir)
        path = File.readlink(dir)
        dir = File.expand_path("../#{path}", dir)
      end
      p "ADDING #{dir} TO WATCH LIST"
      ary << DirectoryWatcher.new(dir,
        :glob => GLOB,
        :scanner => :rev,
        :pre_load => true)
    end

    # SIGHUP makes unicorn respawn workers
    dws.each do |dw|
      dw.add_observer do |*args|
        p "=" * 20
        p "RELOADING"
        p "=" * 20
        Process.kill :HUP, pid
      end
    end

    # wrap this in a lambda, just to avoid repeating it
    stop = lambda { |sig|
      reloader_active[true] if $reloader_was_deactivated
      Process.kill :QUIT, pid # kill unicorn
      dws.each(&:stop)
      log_watch.stop
      exit
    }

    trap("INT", stop)

    log_watch.start
    dws.each(&:start)
    puts "Hit RETURN to terminate"
    $stdin.gets # when the user hits "enter" the script will terminate
    stop.call(nil)
  end
end

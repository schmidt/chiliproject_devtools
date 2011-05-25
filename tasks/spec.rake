require 'spec/rake/spectask'

spec_prereq = File.exist?(File.join(RAILS_ROOT, 'config', 'database.yml')) ? "db:test:prepare" : :noop

namespace :dev do
  task :generate_rspec do |t|
    unless File.exists?(File.join(RAILS_ROOT, 'lib', 'tasks', 'rspec.rake'))
      puts "Running script/generate rspec..."
      system("cd '#{RAILS_ROOT}' && script/generate rspec")
    end
  end
end

namespace :redmine do
  namespace :spec do
    def define_rake_task(folder, options = {})
      plugin_name = folder.to_s.split("/").last
      short_name = plugin_name.sub /^(redmine|chiliproject)_/, ''
      description = "Run specs in #{plugin_name}"

      Spec::Rake::SpecTask.new(plugin_name => ["db:test:prepare", "dev:generate_rspec"]) do |t|
        t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
        t.spec_files = FileList["#{folder}/spec/**/*_spec.rb"]
      end

      task short_name => plugin_name unless short_name == plugin_name
    end

    spec_folders = Dir.glob(File.join(RAILS_ROOT, "vendor/plugins/*/spec"))
    # exclude failing Gravatar specs from Redmine Core
    spec_folders.delete(File.join(RAILS_ROOT, "vendor/plugins/gravatar/spec"))
    spec_folders.each do |folder|
      define_rake_task(File.dirname(folder))
    end

    task :all do
      success = true

      if ENV.has_key?("TEST_PART")
        tests = spec_folders.sort
        part_of = ENV["TEST_PART"].split("of")
        part = part_of.first.to_f
        total_parts = part_of.last.to_i
        test_count = tests.length
        parts = ((part - 1)/total_parts * test_count).to_i..(((part)/total_parts * test_count) - 1).to_i
        tests = tests[parts]
        puts "rspec TEST_PART: Selected #{parts} out of #{test_count} tests. Part numbering begins with zero."
        spec_folders = tests
      end

      spec_folders.each do |folder|
        plugin_name = File.dirname(folder).to_s.split("/").last.to_sym

        # run per-plugin specs in own processes
        sh "rake redmine:spec:#{plugin_name}" do |ok, res|
          success &= ok
        end
      end
      if not success
        exit 1
      end
    end
  end
end

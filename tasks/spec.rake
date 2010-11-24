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


namespace :spec do
  namespace :plugins do

    Spec::Rake::SpecTask.new(:all => ["db:test:prepare", "dev:generate_rspec"]) do |t|
      t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
      t.spec_files = FileList['vendor/plugins/**{,/*/**}/spec/**/*_spec.rb'].exclude('vendor/plugins/rspec/*').exclude("vendor/plugins/rspec-rails/*")
    end
    # alternative approach using plugin spec:plugin tasks
    #
    # task :all do |t|
    #   plugin_spec_tasks = Rake.application.tasks.select { |t|
    #     t.name =~ /^spec:plugins:/ && t.name != "spec:plugins:all"
    #   }
    #   plugin_spec_tasks.each do |t|
    #     print "Running specs: #{t.name}\n"
    #     t.invoke
    #   end
    # end
  end
end
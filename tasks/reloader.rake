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
end

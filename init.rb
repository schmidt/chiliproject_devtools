require 'active_support'

class ::Object
  def presence
    blank? ? nil : self
  end
end

options = [
  :warnings_on_first_load, :history, :loaded, :mechanism, :autoloaded_constants, :autoload_paths,
  :autoload_once_paths, :explicitly_unloadable_constants, :logger, :log_activity, :default_strategy,
  :constant_watch_stack, :dependencies, :world_reload_count, :reload_count, :checked_updates, :mtimes,
  :mutex, :check_mtime, :invalidate_old, :load_paths, :load_once_paths
].inject({}) do |opts, key|
  opts[key] = ActiveSupport::Dependencies.send(key) if ActiveSupport::Dependencies.respond_to? key
  opts
end

require 'fixed_dependencies'

class << ActiveSupport::Dependencies
  alias load_paths autoload_paths
  alias load_once_paths autoload_once_paths
  alias load_paths= autoload_paths=
  alias load_once_paths= autoload_once_paths=
end

options.each do |key, value|
  ActiveSupport::Dependencies.send("#{key}=", value)
end

ActiveSupport::Dependencies.autoload_paths += Dir.glob(File.join(RAILS_ROOT, '{,vendor/*/*/}{app/*,lib}'))

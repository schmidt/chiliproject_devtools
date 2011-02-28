require 'factory_girl'

module RedmineFactoryGirl
  module FactoryPatch
    def self.included(base) # :nodoc:
      base.class_eval do

        def self.add_to (name, options = {})
          instance = self.factories[name]
          if instance
            yield(instance)
          else
            instance = Factory.new(name)
            yield(instance)
            self.factory_add_to[name] = instance
          end
        end

        def self.define_with_add_to (name, options = {})
          define_without_add_to(name,options) do |instance|
            yield(instance)
          end

          addition = self.factory_add_to[name.to_sym]

          if addition
            instance = self.factories[name]
            instance.attributes.concat addition.attributes
            self.factory_add_to.delete(name.to_sym)
          end
        end

        class << self
          attr_accessor :factory_add_to

          alias_method :define_without_add_to, :define unless method_defined?(:define_without_add_to)
          alias_method :define, :define_with_add_to
        end

        self.factory_add_to = {}
      end
    end
  end
end

Factory.send(:include, RedmineFactoryGirl::FactoryPatch)


factory_dirs = Dir["vendor/plugins/*/spec/factories"]

factory_dirs.each do |dir_name|
  files = Dir.new(dir_name).entries.grep /^[^\.].*\.rb$/
  files.each do |file_name|
    require File.join(dir_name, file_name)
  end
end

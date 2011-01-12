module TestReplacer
  def self.included(base)
    base.class_eval do
      def replacement(name)
        return methods.detect {|x| x.include? "replacement_#{name}" }
      end

      def replace_tests
        new_test = replacement(instance_variable_get(:@method_name))
        if new_test
          instance_variable_set(:@method_name, new_test)
        end
      end

      def initialize(*args)
        super(*args)

        replace_tests
      end
    end
  end
end
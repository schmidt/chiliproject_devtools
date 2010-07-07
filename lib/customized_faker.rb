require 'ffaker'

Faker.class_eval do
  Faker::Company.class_eval do
    class << self
      def bs_category
        @@bs_category ||= [
          "Investment",
          "Research",
          "Contracts",
          "Upgrades",
          "Feedback",
          "Accounting",
          "Strategies"]
        @@bs_category.delete(@@bs_category.shuffle.first)
      end
    end
  end
end
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
      
      def catch_phrase_id
        @@catch_phrase_id ||= [
          "Page ID",
          "Account Info",
          "Administration Key",
          "WBF Information",
          "Management Sign",
          "eBook Reference"]
        @@catch_phrase_id.delete(@@catch_phrase_id.shuffle.first)
      end
    end
  end
end
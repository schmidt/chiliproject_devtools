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
        ret = @@bs_category.delete(@@bs_category.shuffle.first)
        @@bs_category = nil if @@bs_category.empty? # reset after we've gone through all
        ret
      end
      
      def catch_phrase_id
        @@catch_phrase_id ||= [
          "Page ID",
          "Account Info",
          "Administration Key",
          "WBF Information",
          "Management Sign",
          "eBook Reference"]
        ret = @@catch_phrase_id.delete(@@catch_phrase_id.shuffle.first)
        @@catch_phrase_id = nil if @@catch_phrase_id.empty?
        ret
      end
    end
  end
end
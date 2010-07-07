require 'ffaker'
require 'populator'

Populator.class_eval do
  class << self
    def words(num = 1)
      Faker::Company.catch_phrase
    end
  end
end

Faker.class_eval do
  Faker::Lorem.class_eval do
    class << self
      def paragraphs(count = 3)
        ["An explanatory text.", "This text explains some things",
          "This content is user-defined"]
      end

      def words(num = 3)
        @@words ||= ["Mile", "Word", "Hour", "Graphic"]
        if num == 1
          @@words.delete(@@words.shuffle.last)
        else
          @@words.shuffle[0 - num].join(" ")
        end
      end
    end
  end

  Faker::Internet.class_eval do
    class << self
      def domain_name
        "http://www.finn.de"
      end
    end
  end

  Faker::Company.class_eval do
    class << self
      def bs        
        @@bs ||= [
          "Find investors",
          "Research into SOA",
          "Sign contract for S3",
          "Upgrade server hardware",
          "Prolong server contract",
          "Solve the server problem",
          "Provide accounting feedback",
          "Calculate cost reports",
          "Collect usage statistics",
          "Increase customer satisfaction",
          "Revise marketing strategy",
          "Evaluate employee performances",
          "Update design guides",
          "Evaluate feedback",
          "Update feedback categories",
          "Interview candidate",
          "Select the new CMS",
          "Wrong URL in Adword",
          "Create a team photo wall",
          "Error reporting in customer views",
          "Jour-Fixe"]
        result = @@bs.shuffle.first
        @@bs.delete(result)
        @@bs = nil if @@bs.empty? # reset after we've gone through all
        result
      end     
      
      def catch_phrase
        @@catch_phrase ||= ["Marketing", "Development", "Graphics",
          "Controlling", "Feedback", "Maintenance", "Service", "Payments"]
          p "Remaining catch phrases: #{@@catch_phrase}"
        @@catch_phrase.delete(@@catch_phrase.shuffle.first)
      end
    end
  end
end
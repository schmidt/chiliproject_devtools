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
          "It's content is user-defined"]
      end
      
      def words(num = 3)
        ["Mile", "Word", "Hour", "Graphic"].shuffle[0 - num]
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
        ["Solve the server problem",
          "Provide accounting feedback",
          "Calculate cost reports",
          "Collect usage statistics"].shuffle.first          
      end
      
      def catch_phrase
        ["Marketing", "Development", "Graphics", "External Controlling", 
          "Feedback", "Maintenance"].shuffle.first
      end
    end
  end
end
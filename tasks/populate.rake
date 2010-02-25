namespace :dev do
  namespace :populate do

    task :prepare => :environment do
      begin
        require "populator"
        begin
          require "ffaker"
        rescue LoadError
          require "faker"
          $stderr.puts "to speed things up, install ffaker"
        end
      rescue LoadError => e
        $stderr.puts "please install gems populator and faker or ffaker"
        raise e
      end
    end
    
    desc "generate some project fake data"
    task :projects => :prepare do
      Project.populate 2..4 do |p|
        p.name        = Populator.words(1..3).titleize
        p.description = Faker::Lorem.paragraphs
        p.created_on  = 3.years.from_now..1.year.from_now
        p.identifier  = "project" + Project.count.to_s
      end
    end
    
    desc "generate some user fake data"
    task :users => :prepare do
      User.populate 10..30 do |u|
        u.firstname     = Faker::Name.first_name
        u.lastname      = Faker::Name.last_name
        name            = "#{u.firstname} #{u.lastname}"
        u.login         = Faker::Internet.user_name name
        u.mail          = Faker::Internet.email name
        u.created_on    = 3.years.from_now..1.year.from_now
        u.last_login_on = 1.year.from_now..Time.now
      end
    end

  end
end
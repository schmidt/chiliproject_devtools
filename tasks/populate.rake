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

    desc "generate default issue statuses"
    task :issue_statuses => :prepare do
      IssueStatus.create(:name => "Closed", :default_done_ratio => 100)
      IssueStatus.create(:name => "In Review", :default_done_ratio => 80)
      IssueStatus.create(:name => "Done", :default_done_ratio => 80)
      IssueStatus.create(:name => "In progress", :default_done_ratio => 50)
      IssueStatus.create(:name => "Rejected")
      IssueStatus.create(:name => "Duplicate")
      IssueStatus.create(:name => "New")
    end

    desc "generate some project fake projects"
    task :projects => [:prepare, :users, :issue_statuses] do
      Project.populate 2..4 do |p|
        p.name              = Populator.words(1..3).titleize
        p.description       = Faker::Lorem.paragraphs
        p.created_on        = 3.years.ago..1.year.ago
        p.identifier        = Faker::Company.name
        IssueCategory.populate 1 do |c|
          c.name        = Faker::Company.bs.slice(0..28)
          c.project_id  = p.id
        end
      end
    end

    desc "generate some issues"
    task :issues => :projects do
      Issue.populate 50..100 do |i|
        i.project_id      = Project.find(rand(Project.count) + 1).id
        i.subject         = Faker::Company.catch_phrase
        i.description     = Faker::Lorem.paragraphs
        i.due_date        = 3.years.from_now..1.year.from_now
        i.category_id     = IssueCategory.find(rand(IssueCategory.count) + 1).id
        i.status_id       = IssueStatus.find(rand(IssueStatus.count) + 1).id
        i.assigned_to_id  = User.find(rand(User.count) + 1).id
        i.created_on      = 3.years.ago..1.year.ago
        i.updated_on      = 1.year.ago..Time.now
        i.start_date      = 1.year.ago..Time.now
        i.done_ratio      = 80..100
        i.estimated_hours = 1..10
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
        u.created_on    = 3.years.ago..1.year.ago
        u.last_login_on = 1.year.ago..Time.now
      end
    end
  end

  desc "generate everything"
  task :populate => %w[populate:users populate:projects populate:issues]
end

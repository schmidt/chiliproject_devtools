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
      Project.populate 4..8 do |p|
        p.name              = Populator.words(1..3).titleize
        p.description       = Faker::Lorem.paragraphs
        p.created_on        = 3.years.ago..1.year.ago
        p.identifier        = Faker::Company.name
        p.is_public         = 1
        p.status            = 1
        p.lft               = p.id*2-1
        p.rgt               = p.id*2
        p.homepage          = Faker::Internet.domain_name
        Redmine::AccessControl.available_project_modules.each do |name|
          EnabledModule.populate(1) do |m|
            m.name = name.to_s
            m.project_id = p.id
          end
        end
        IssueCategory.populate 1 do |c|
          c.name        = Faker::Company.bs.slice(0..28)
          c.project_id  = p.id
        end
      end
      Project.all.each do |p|
        p.trackers = Tracker.all
        p.save!
      end
    end

    desc "generate some issues"
    task :issues => [:users, :projects] do
      Issue.populate 500..1000 do |i|
        i.project_id      = rand(Project.count) + 1
        i.subject         = Faker::Company.catch_phrase
        i.description     = Faker::Lorem.paragraphs
        i.due_date        = 3.years.from_now..1.year.from_now
        i.category_id     = rand(IssueCategory.count) + 1
        i.status_id       = rand(IssueStatus.count) + 1
        i.assigned_to_id  = rand(User.count) + 1
        i.author_id       = rand(User.count) + 1
        i.created_on      = 3.years.ago..1.year.ago
        i.updated_on      = 1.year.ago..Time.now
        i.start_date      = 1.year.ago..Time.now
        i.done_ratio      = 80..100
        i.estimated_hours = 1..10
        i.tracker_id      = 1..3
        i.priority_id     = 3..7
      end
    end

    desc "generate some user fake data"
    task :users => :prepare do
      User.populate 20..30 do |u|
        u.firstname     = Faker::Name.first_name
        u.lastname      = Faker::Name.last_name
        name            = "#{u.firstname} #{u.lastname}"
        u.login         = Faker::Internet.user_name name
        u.mail          = Faker::Internet.email name
        u.created_on    = 3.years.ago..1.year.ago
        u.last_login_on = 1.year.ago..Time.now
        u.hashed_password = User.hash_password("initial123")
      end
    end
  end

  desc "generate everything"
  task :populate => %w[populate:users populate:projects populate:issues]
end

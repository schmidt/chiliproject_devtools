namespace :dev do
  namespace :populate do
    
    # Taken from _why's "Poignant Guide"
    class Array
      def / len
        a = []
        each_with_index do |x,i|
          a << [] if i % len == 0
          a.last << x
        end
        a
      end
    end

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
        name = "#{Populator.words(1).titleize} #{p.id}"
        p.name              = name
        p.description       = Faker::Lorem.paragraphs
        p.created_on        = 3.years.ago..1.year.ago
        p.identifier        = name
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
    
    desc "Make some subprojects"
    task :subprojects => [:prepare, :projects] do
      top, bottom = Project.all / (Project.count / 2)
      bottom.each_with_index { |p,idx| p.set_parent!(top[idx]) }
    end
    
    desc "generate some issue custom fields with values"
    task :issue_custom_fields => [:prepare, :projects, :issues] do
      IssueCustomField.populate(Project.count) do |f|
        f.type            = "IssueCustomField"
        f.name            = "CustomField #{f.id}"
        f.field_format    = "string"
        f.possible_values = "--- []\n\n"
        f.min_length      = 0
        f.max_length      = 0
        f.is_required     = 0
        f.is_for_all      = 0
        f.is_filter       = 1
        f.position        = 1
        f.searchable      = 1
        f.editable        = 1
      end
      IssueCustomField.all.each do |f|
        (rand(3) + 1).times do |i|
          project = Project.find(rand(Project.count) + 1)
          project.issue_custom_fields << f
          CustomValue.populate (((project.issues.count / 2).to_i)..(project.issues.count)) do |v|
            v.customized_type = "Issue"
            v.customized_id   = project.issues[rand(project.issues.count) - 1].id
            v.custom_field_id = f.id
            letters = 3.times.collect {|i| ("A".."K").to_a.shuffle.first}
            numbers = 2.times.collect {|i| ("0".."4").to_a.shuffle.first}
            type    = ["A", "B", "E", "G"].shuffle.first
            v.value           = letters.join + numbers.join + type
          end
        end
      end
    end

    desc "generate some issues"
    task :issues => [:users, :projects] do
      Project.count.times do |id|
        Issue.populate 500..1000 do |i|
          i.project_id      = id + 1
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

    desc "Generate some time entries"
    task :time_entries => [:prepare, :issues] do
      TimeEntry.populate ((Issue.count)..(Issue.count * 2)) do |t|
        issue = Issue.find(rand(Issue.count) + 1)
        t.project_id  = issue.project.id
        t.user_id     = issue.author.id
        t.issue_id    = issue.id
        t.hours       = 1..10
        t.comments    = Faker::Lorem.paragraphs
        t.activity_id = 9..10
        spent_on = (1..100).to_a.shuffle.first.days.ago.send(:to_date)
        t.spent_on    = spent_on
        t.tyear       = spent_on.year
        t.tmonth      = spent_on.month
        t.tweek       = spent_on.cweek
      end
    end
    
    desc "Assign users to projects"
    task :users_projects => [:users, :projects] do
      User.all.each do |u|
        projects = (Project.all / [1,2,3].shuffle.first).first
        projects.each do |p|
          m = Member.create!(:user_id => u.id, :project_id => p.id)
          role = Role.collect{|r| !builtin}.shuffle.first
          MemberRole.create!(:member_id => m.id, :role_id => role.id)
        end
      end
    end
    
    desc "Generate some time rates"
    task :rates => [:prepare, :users_projects] do
      User.count.times do |idx|
        Rate.populate 1 do |r|
          r.valid_from = 3.years.ago..2.years.ago
          r.rate       = 5..50
          r.user_id    = idx + 1
          r.type = DefaultHourlyRate
        end
      end
      Project.all.each do |p|
        p.users.each do |u|
          if (rand(2) == 0) # 50/50 chance that this user has a project specific rate
            Rate.populate 1..3 do |r|
              r.valid_from  = (50-r.id).days.ago
              r.rate        = 10.50
              r.user_id     = u.id
              r.project_id  = p.id
              r.type        = HourlyRate
            end
          end
        end
      end
    end

    desc "Generate some cost_types"
    task :cost_types => [:prepare] do
      CostType.populate 2..5 do |c|        
        unit = Faker::Lorem.words(1)
        c.name        = "A standard #{unit}"
        c.unit        = unit
        c.unit_plural = "#{unit}s"
        c.default     = false
      end
      CostType.first.tap do |c|
        c.default = true
      end.save!
    end
    
    desc "Generate some cost rates"
    task :cost_rates => [:cost_types] do
      CostType.count.times do |c_id|
        r.rate = 3..13
        r.type = CostRate
      end
    end
    
    desc "Generate some time entries"
    task :cost_entries => [:issues, :cost_types] do
      CostEntry.populate (Issue.count..(Issue.count * 2)) do |t|
        issue = Issue.find(rand(Issue.count) + 1)
        t.project_id    = issue.project.id
        t.user_id       = issue.author.id
        t.issue_id      = issue.id
        t.units         = 1..10
        t.comments      = Faker::Lorem.paragraphs
        spent_on = (1..100).to_a.shuffle.first.days.ago.send(:to_date)
        t.spent_on      = spent_on
        t.tyear         = spent_on.year
        t.tmonth        = spent_on.month
        t.tweek         = spent_on.cweek
        t.cost_type_id  = rand(CostType.count) + 1
      end
    end
  end

  desc "generate everything"
  task :populate => %w[populate:users populate:projects populate:subprojects populate:users_projects 
    populate:issues populate:issue_custom_fields populate:time_entries populate:cost_entries 
    populate:cost_rates populate:rates]
end

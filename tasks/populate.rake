$LOAD_PATH.unshift(File.expand_path(File.join(__FILE__, "..", "..", "lib")))
require 'customized_faker'

namespace :dev do
  namespace :populate do
    
    # Taken from _why's "Poignant Guide" - ok
    class Array
      def / len
        a = []
        each_with_index do |x,i|
          a << [] if i % [len, 1].max == 0
          a.last << x
        end
        a
      end
    end

    # On PostgreSQL, the primary key sequence is not updated by Populator
    def reindex_all_pkeys
      ActiveRecord::Base.send(:subclasses).collect(&:table_name).each do |table|
        ActiveRecord::Base.connection.reset_pk_sequence!(table)
      end
    end

    def populate_project(range)
      used_names = Project.all.collect(&:name)
      Project.populate range do |p|
        while used_names.include? (name = "#{Populator.words(1).titleize}"); end
        used_names << name
        p.name              = name.slice(0..29)
        p.description       = Faker::Lorem.paragraphs
        p.created_on        = 3.months.ago..1.month.ago
        p.identifier        = name.underscore[([-name.underscore.length, -18].max)..-1]
        p.is_public         = true
        p.status            = 1
        p.lft               = p.id*2-1
        p.rgt               = p.id*2
        p.homepage          = Faker::Internet.domain_name.slice(0..253)
        Redmine::AccessControl.available_project_modules.each do |name|
          EnabledModule.populate(1) do |m|
            m.name = name.to_s
            m.project_id = p.id
          end
        end
        IssueCategory.populate 1 do |c|
          c.name        = Faker::Company.bs_category.slice(0..28)
          c.project_id  = p.id
        end
      end
      Project.all.each do |p|
        p.trackers = Tracker.all
        p.save!
      end
    end
    
    def populate_issues(range, project_id)
      Issue.populate range do |i|
        i.project_id      = project_id + 1
        i.subject         = Faker::Company.bs.slice(0..253)
        i.description     = Faker::Lorem.paragraphs
        i.due_date        = 3.months.from_now..1.month.from_now
        i.category_id     = rand(IssueCategory.count) + 1
        i.status_id       = rand(IssueStatus.count) + 1
        i.assigned_to_id  = rand(User.count - 2) + 3
        i.author_id       = rand(User.count - 2) + 3
        i.created_on      = 3.months.ago..1.month.ago
        i.updated_on      = 1.month.ago..Time.now
        i.start_date      = 1.month.ago..Time.now
        i.done_ratio      = 80..100
        i.estimated_hours = 1..10
        i.tracker_id      = 1..3
        i.priority_id     = 3..7
        i.lock_version    = 1
        i.cost_object_id  = Project.find(project_id + 1).cost_objects.shuffle.first.try(:id) if rand(3) != 0
        # 1/3rd chance of no cost object
      end
    end

    def populate_users(range)
      used_names = User.all.collect(&:login)
      User.populate range do |u|
        first, last, name, mail, login = nil
        loop do
          first = Faker::Name.first_name.slice(0..28)
          last  = Faker::Name.last_name.slice(0..28)
          name  = "#{first} #{last}"
          mail  = Faker::Internet.email(name).slice(0..58)
          login = Faker::Internet.user_name(name).slice(0..28)
          break unless used_names.include? login
        end
        used_names << login

        u.firstname       = first
        u.lastname        = last
        u.login           = login
        u.mail            = mail
        u.created_on      = 3.months.ago..1.month.ago
        u.last_login_on   = 1.month.ago..Time.now
        u.hashed_password = User.hash_password("admin")
        u.status          = 1
        u.mail_notification = false
        u.admin           = (rand() >= 0.5)
      end
    end
    
    def populate_cost_types(range)
      CostType.populate range do |c|
        unit = Faker::Lorem.words(1)
        c.name        = "A standard #{unit}"
        c.unit        = unit
        c.unit_plural = "#{unit}s"
        c.default     = false
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
    task :projects, :count, :needs => [:prepare, :users, :issue_statuses] do |t, args|
      count = args[:count].to_i unless (args[:count].to_i == 0)
      count ||= 4..8
      populate_project(count)
    end
    
    desc "Make some subprojects"
    task :subprojects => [:prepare, :projects] do
      top, bottom = Project.all / (Project.count / 2)
      unless bottom.nil?
        bottom.each_with_index { |p,idx| p.set_parent!(top[idx]) }
      end
    end
    
    desc "generate some issue custom fields with values"
    task :issue_custom_fields => [:prepare, :projects, :issues] do
      IssueCustomField.populate(5) do |f|
        f.type            = "IssueCustomField"
        f.name            = Faker::Company.catch_phrase_id.slice(0..28)
        f.field_format    = "string"
        f.possible_values = "--- []\n\n"
        f.min_length      = 0
        f.max_length      = 0
        f.is_required     = false
        f.is_for_all      = false
        f.is_filter       = true
        f.position        = 1
        f.searchable      = true
        f.editable        = true
      end
      Tracker.all.each do |t|
        IssueCustomField.all.each do |cf|
          t.custom_fields << cf
        end
      end
      IssueCustomField.all.each do |f|
        (rand(3) + 1).times do |i|
          project = Project.find(rand(Project.count) + 1)
          project.issue_custom_fields << f
          CustomValue.populate (((project.issues.count / 2).to_i)..(project.issues.count)) do |v|
            v.customized_type = "Issue"
            v.customized_id   = project.issues[rand(project.issues.count) - 1].id
            v.custom_field_id = f.id
            
            letters = 3.times.collect {|i| ("A".."C").to_a.shuffle.first}
            numbers = 2.times.collect {|i| ("0".."2").to_a.shuffle.first}
            type    = ["A", "B", "E", "G"].shuffle.first
            course  = letters.join + numbers.join + type
            ebook   = "A#{("0".."2").to_a.shuffle.first*2}_M#{("0".."2").to_a.shuffle.first*2}_L#{("0".."2").to_a.shuffle.first*2}"
            bogus   = "Evaluation required"
            
            v.value = [course, course, course, ebook, ebook, bogus].shuffle.first
          end
        end
      end
    end

    desc "generate some issues"
    task :issues, :count, :needs => [:users, :projects, :cost_objects] do |t, args|
      count = args[:count].to_i unless (args[:count].to_i == 0)
      count ||= 500..1000
      Project.count.times do |id|
        populate_issues(count, id)
      end
    end

    desc "generate some user fake data"
    task :users, :count, :needs => [:prepare] do |t, args|
      count = args[:count].to_i unless (args[:count].to_i == 0)
      count ||= 20..30
      populate_users count
    end

    desc "Generate some time entries"
    task :time_entries => [:prepare, :issues] do
      TimeEntry.populate ((Issue.count)..(Issue.count * 3)) do |t|
        issue = Issue.find(rand(Issue.count) + 1)
        spent_on = (1..70).to_a.shuffle.first.days.ago.send(:to_date)

        t.project_id  = issue.project.id
        t.user_id     = issue.author.id
        t.issue_id    = ([issue.id] * 5 + [nil]).shuffle.first
        t.hours       = 1..10
        t.comments    = ""
        t.activity_id = TimeEntryActivity.all.shuffle.first.id
        t.spent_on    = spent_on
        t.tyear       = spent_on.year
        t.tmonth      = spent_on.month
        t.tweek       = spent_on.cweek
      end
    end
    
    desc "Assign users to projects"
    task :users_projects => [:users, :projects] do
      User.all[2..-1].each do |u|
        projects = (Project.all / [1,2,3].shuffle.first).first
        projects.each do |p|
          next if p.members.collect(&:user_id).include? u.id
          Member.new.tap do |m|
            m.user = u
            m.roles << Role.all.select{|r| r.builtin == 0}.shuffle.first
            m.project = p
          end.save!
        end
      end
    end
    
    desc "Generate some time rates"
    task :rates => [:users_projects] do
      (User.count - 2).times do |idx|
        next unless User.find(idx + 3).default_rates.empty?
        DefaultHourlyRate.populate 1 do |r|
          r.valid_from = 3.months.ago..2.months.ago
          r.rate       = 5..50
          r.user_id    = idx + 3
        end
      end
      Project.all.each do |p|
        p.users.each do |u|
          if (rand(2) == 0) # 50/50 chance that this user has a project specific rate
            HourlyRate.populate 1..3 do |r|
              r.valid_from  = (50-r.id).days.ago
              r.rate        = 10.50
              r.user_id     = u.id
              r.project_id  = p.id
            end
          end
        end
      end
    end

    desc "Generate some cost_types"
    task :cost_types, :count, :needs => [:prepare] do |t, args|
      count = args[:count].to_i unless (args[:count].to_i == 0)
      count ||= 2..5
      populate_cost_types count
      CostType.first.tap do |c|
        c.default = true
      end.save!
    end

    desc "Generate some cost rates"
    task :cost_rates => [:cost_types] do
      CostType.all.each do |ct|
        User.current = User.first
        CostRate.create!(
            :valid_from => 3.months.ago.to_date,
            :rate => (3..13).to_a.shuffle.first,
            :user => User.first,
            :cost_type => ct)
      end
    end
    
    desc "Generate some cost entries"
    task :cost_entries => [:issues, :cost_types] do
      CostEntry.populate (Issue.count..(Issue.count * 3)) do |t|
        issue = Issue.find(rand(Issue.count) + 1)
        spent_on = (1..70).to_a.shuffle.first.days.ago.send(:to_date)

        t.project_id    = issue.project.id
        t.user_id       = issue.author.id
        t.issue_id      = issue.id
        t.units         = 1..10
        t.comments      = ""
        t.blocked       = false
        t.spent_on      = spent_on
        t.tyear         = spent_on.year
        t.tmonth        = spent_on.month
        t.tweek         = spent_on.cweek
        t.cost_type_id  = rand(CostType.count) + 1
      end
    end

    desc "Generate a few cost objects"
    task :cost_objects => [:projects] do |c|
      first, second = Project.all / (Project.count / 3)
      first += second unless second.nil?
      first.each do |p|
        CostObject.populate 1..2 do |co|
          co.project_id               = p.id
          co.author_id                = p.members.shuffle.first.user_id
          co.subject                  = Faker::Company.bs_category
          co.description              = Faker::Lorem.paragraphs(1)
          co.type                     = "VariableCostObject"
          co.project_manager_signoff  = false
          co.client_signoff           = false
          co.fixed_date               = 2.month.ago..2.months.from_now
      end
    end
  end

  desc "generate everything"
  task :populate_few => :"dev:populate:prepare" do
    require 'friendly_faker'
    Rake::Task["dev:populate:users"].invoke(4)
    Rake::Task["dev:populate:projects"].invoke(4)
    Rake::Task["dev:populate:subprojects"].invoke
    Rake::Task["dev:populate:users_projects"].invoke
    Rake::Task["dev:populate:issues"].invoke(10)
    Rake::Task["dev:populate:issue_custom_fields"].invoke
    Rake::Task["dev:populate:time_entries"].invoke
    Rake::Task["dev:populate:cost_types"].invoke(3)
    Rake::Task["dev:populate:cost_entries"].invoke
    Rake::Task["dev:populate:cost_rates"].invoke
    Rake::Task["dev:populate:rates"].invoke
    reindex_all_pkeys
  end

  desc "generate everything"
  task :populate_lots => %w[populate:users populate:projects populate:subprojects populate:users_projects
    populate:issues populate:issue_custom_fields populate:time_entries populate:cost_entries
    populate:cost_rates populate:rates] do
      reindex_all_pkeys
  end
end

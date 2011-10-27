Factory.define :issue do |i|
  i.association :priority, :factory => :priority
  i.sequence(:subject) { |n| "Issue No. #{n}" }
  i.description { |i| "Description for '#{i.subject}'" }
  i.association :tracker, :factory => :tracker_feature
  i.association :author, :factory => :user
end

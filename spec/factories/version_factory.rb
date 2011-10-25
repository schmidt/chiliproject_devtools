Factory.define :version do |v|
  v.sequence(:name) { |i| "Version #{i}" }
  v.effective_date Date.today + 14.days
  v.association :project, :factory => :project
end

Factory.define :version do |v|
  v.name "version"
  v.effective_date Date.today + 14.days
  v.association :project, :factory => :project
end
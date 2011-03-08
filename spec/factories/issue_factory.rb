Factory.define :issue do |i|
  i.association :priority, :factory => :priority
  i.subject "Can't print recipes because you have to cook them"
  i.description "Unable to print recipes"
  i.association :tracker, :factory => :tracker_feature
  i.association :author, :factory => :user
end
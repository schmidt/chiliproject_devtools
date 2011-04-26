Factory.define :tracker do |t|
  t.position { Tracker.find(:last, :order => 'position').position + 1 }
  t.name { |a| "Tracker #{a.position}" }
end

Factory.define :tracker_bug, :class => Tracker do |t|
  t.name "Bug"
  t.is_in_chlog true
  t.position 1
end

Factory.define :tracker_feature, :parent => :tracker_bug do |t|
  t.name "Feature"
  t.position 2
end

Factory.define :tracker_suport, :parent => :tracker_bug do |t|
  t.name "Support"
  t.position 3
end

Factory.define :tracker_task, :parent => :tracker_bug do |t|
  t.name "Task"
  t.position 4
end

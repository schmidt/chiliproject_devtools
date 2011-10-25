Factory.define :priority, :class => IssuePriority do |p|
  p.sequence(:name) { |i| "Priority #{i}" }
  p.active true
end

Factory.define :priority_low, :parent => :priority do |p|
  p.name "Low"
end

Factory.define :priority_normal, :parent => :priority do |p|
  p.name "Normal"
end

Factory.define :priority_high, :parent => :priority do |p|
  p.name "High"
end

Factory.define :priority_urgent, :parent => :priority do |p|
  p.name "Urgent"
end

Factory.define :priority_immediate, :parent => :priority do |p|
  p.name "Immediate"
end

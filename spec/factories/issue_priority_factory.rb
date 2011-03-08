Factory.define :priority, :class => IssuePriority do |p|
  p.name "Normal"
  p.active true
end

Factory.define :priority_low, :parent => :priority do |p|
  p.name "Low"
end

Factory.define :priority_high, :parent => :priority do |p|
  p.name "High"
end

Factory.define :priority_urgent, :parent => :priority do |p|
  p.name "urgent"
end

Factory.define :priority_immediate, :parent => :priority do |p|
  p.name "Immediate"
end
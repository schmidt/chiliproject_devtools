Factory.define :role do |r|
  r.permissions    []
  r.sequence(:name) { |n| "role_#{n}"}
  r.assignable true
end
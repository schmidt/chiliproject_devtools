Factory.define :role do |r|
  r.permissions    []
  r.sequence(:name) { |n| "role_#{n}"}
  r.assignable true
end

Factory.define :non_member, :parent =>:role do |r|
  r.name "Non member"
  r.builtin Role::BUILTIN_NON_MEMBER
  r.assignable false
end

Factory.define :anonymous_role, :parent => :role do |r|
  r.name "Anonymous"
  r.builtin Role::BUILTIN_ANONYMOUS
  r.assignable false
end
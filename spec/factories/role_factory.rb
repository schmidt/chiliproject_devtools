Factory.define :role do |r|
  r.permissions    []
  r.sequence(:name) { |n| "role_#{n}"}
  r.assignable true
end

Factory.define :non_member, :class => Role do |r|
  r.name "Non member"
  r.builtin Role::BUILTIN_NON_MEMBER
  r.assignable true
end

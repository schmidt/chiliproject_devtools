Factory.define :non_member, :class => Role do |r|
  r.name "Non member"
  r.builtin Role::BUILTIN_NON_MEMBER
  r.assignable true
end
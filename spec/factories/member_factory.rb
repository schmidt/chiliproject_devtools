Factory.define :member do |m|
  m.user    Factory.build :user
  m.project Factory.build :project
end
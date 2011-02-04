Factory.define :member do |m|
  m.association    :user, :factory => :user
  m.association    :project, :factory => :project
end
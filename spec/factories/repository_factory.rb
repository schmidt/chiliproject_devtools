Factory.define :repository, :class => Repository::Filesystem do |r|
  r.url  'file:///tmp/test_repo'
  r.association :project, :factory => :project
end


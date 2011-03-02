Factory.define(:wiki) do |p|
  p.start_page 'Wik'

  p.association :project, :factory => :project
end


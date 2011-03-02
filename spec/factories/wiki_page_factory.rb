Factory.define :wiki_page do |w|
  w.association :wiki, :factory => :wiki
  w.sequence(:title) { |n| "Wiki Page No. #{n}" }
end

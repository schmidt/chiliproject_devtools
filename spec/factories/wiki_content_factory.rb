Factory.define :wiki_content do |w|
  w.association :page, :factory => :wiki_page
  w.association :author, :factory => :user

  w.text { |a| "h1. #{a.page.title}\n\nPage Content Version #{a.version}." }
end


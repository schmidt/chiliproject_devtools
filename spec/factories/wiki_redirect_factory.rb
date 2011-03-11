Factory.define :wiki_redirect do |r|
  r.association :wiki, :factory => :wiki

  r.title        'Source'
  r.redirects_to 'Target'
end

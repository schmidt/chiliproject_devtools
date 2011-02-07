Factory.define(:project) do |p|
  p.sequence(:name) { |n| "My#{n}" }
  p.sequence(:identifier) { |n| "myproject#{n}" }
  p.enabled_module_names Redmine::AccessControl.available_project_modules
end
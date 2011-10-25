Factory.define(:project) do |p|
  p.sequence(:name) { |n| "My Project No. #{n}" }
  p.sequence(:identifier) { |n| "myproject_no_#{n}" }
  p.enabled_module_names Redmine::AccessControl.available_project_modules
end

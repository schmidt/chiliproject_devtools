Factory.define :user_custom_field do |cv|
  cv.name "UserCustomField"
  cv.regexp ""
  cv.is_required "0"
  cv.min_length "0"
  cv.default_value ""
  cv.max_length "0"
  cv.editable "1"
  cv.possible_values ""
  cv.visible "1"
end

Factory.define :boolean_user_custom_field, :parent => :user_custom_field do |cv|
  cv.name "BooleanUserCustomField"
  cv.field_format "bool"
end
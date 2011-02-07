Factory.define :user do |u|
  u.firstname 'Bob'
  u.lastname 'Bobbit'
  u.login 'bob'
  u.mail 'bob.bobbit@bob.com'
  u.password 'T3stT3st'
  u.password_confirmation 'T3stT3st'
  u.mail_notification true
  u.language 'en'
  u.status User::STATUS_ACTIVE
  u.admin false
end

Factory.define :admin, :class => User do |u|
  u.firstname 'Redmine'
  u.lastname 'Admin'
  u.login 'admin'
  u.password 'admin'
  u.password_confirmation 'admin'
  u.mail 'admin@example.com'
  u.admin true
end

Factory.define :anonymous, :class => AnonymousUser do |u|
  u.lastname "Anonymous"
  u.firstname ""
  u.status User::STATUS_ANONYMOUS
end
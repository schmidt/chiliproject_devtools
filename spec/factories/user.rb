Factory.define :user do |u|
  u.firstname 'Bob'
  u.lastname 'Bobbit'
  u.login 'bob'
  u.mail 'bob.bobbit@bob.com'
  u.admin false
end

Factory.define :admin, :class => User do |u|
  u.firstname 'Admin'
  u.lastname 'Admin'
  u.login 'admin'
  u.mail 'admin@admincentral.com'
  u.admin true
end
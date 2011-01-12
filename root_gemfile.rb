RUBY_ENGINE = 'ruby' unless defined? RUBY_ENGINE
source :rubygems
gem "rails", "2.3.5"
gem "rack", "1.0.1"

gem "rubytree", "0.5.2", :require => "tree"
gem "RedCloth", "~> 4.2.3", :require => "redcloth" # for CodeRay
gem "nokogiri"

gem "sqlite3-ruby", :require => "sqlite3"
gem "mysql", :group => :mysql
gem(RUBY_ENGINE == 'ruby' ? "pg" : "postgres")
gem 'memcache-client'

#gem "i18n", "0.3.7"

if RUBY_ENGINE !~ /jruby/
  gem 'mongrel'
end


group :test do
  gem "shoulda", "~> 2.10.3"
  gem "thoughtbot-shoulda"
  gem "mocha", :require => nil # ":require => nil" fixes obscure bugs - remove and run all tests
  gem "edavis10-object_daddy", :require => "object_daddy"
  gem "test-unit", "~> 1.2.3"
  gem "ruby-debug"
  gem "rcov"
  gem "factory_girl", "~> 1.2.4"
end

# Load plugins' Gemfiles
Dir.glob File.expand_path("../vendor/plugins/*/Gemfile", __FILE__) do |file|
  puts "Loading #{file} ..."
  instance_eval File.read(file)
end

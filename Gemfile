source 'https://rubygems.org'

group :development do
  gem 'pry'
end

group :test do
  gem 'rspec'
  if ENV['CI']
    gem 'coveralls', require: false
  else
    gem 'guard-rspec'
    gem 'rb-fsevent'
  end
end

gem 'rake'

# Specify your gem's dependencies in stormpack.gemspec
gemspec

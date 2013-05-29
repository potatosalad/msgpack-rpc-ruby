source 'https://rubygems.org'

group :development do
  gem 'pry'
end

group :test do
  if ENV['CI']
    gem 'coveralls', require: false
  else
    gem 'guard-rspec'
    gem 'rb-fsevent'
  end
end

# Specify your gem's dependencies in stormpack.gemspec
gemspec

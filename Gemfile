source 'https://rubygems.org'

gem 'json', :platforms => [:jruby, :rbx, :ruby_18]
gem 'rake', '>= 0.9'

group :test do
  gem 'parallel', '= 1.3.3', :platforms => [:mri_19]
  gem 'cane', '>= 2.2.2', :platforms => [:mri_19, :mri_20, :mri_21]
  gem 'rspec', '>= 3'
  gem 'simplecov'
#  gem 'webmock'
end

platforms :ruby_18 do
  gem 'iconv'
end

gemspec

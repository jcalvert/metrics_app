source "https://rubygems.org"

gem "rails", "3.2.12"

group :assets do
  gem "sass-rails",   "~> 3.2.3"
  gem "coffee-rails", "~> 3.2.1"
  gem "uglifier",     ">= 1.0.3"
end

gem "unicorn", ">= 4.3.1"
gem "jquery-rails"
gem "bootstrap-sass", ">= 2.3.0.0"
gem "sendgrid", ">= 1.0.1"

gem "omniauth", ">= 1.1.3"
gem "omniauth-github"
gem "cancan", ">= 1.6.8"
gem "rolify", ">= 3.2.0"

gem "figaro", ">= 0.5.3"
gem 'aws-sdk'
gem "octokit"

group :development do
  gem "quiet_assets", ">= 1.0.1"
  gem "better_errors", ">= 0.6.0"
  gem "binding_of_caller", ">= 0.6.9"
end

group :test do
  gem "minitest-spec-rails", ">= 4.3.8"
  gem "minitest-wscolor", ">= 0.0.3"
end

group :development, :test do
  gem "sqlite3"
end

group :production do
  gem "pg"
end

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.12'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '8.1.4'
gem 'sprockets-rails', '~> 3.5'
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
gem 'pg', '1.6.3'
# Use Puma as the app server
gem 'puma', '8.0.2'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '5.4.4'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '2.15.1'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# user account
gem 'devise', '5.0.4'

# icons
gem 'feathericon-rails'
# icons (fontawesome)
# gem "font-awesome-rails"
gem 'font-awesome-sass'

# toastr
gem 'toastr-rails'

# image uploads to Amazon s3
gem 'carrierwave', '3.1.4'
gem 'fog-aws'

# image resizing
gem 'mini_magick'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '1.26.1', require: false

# google maps
gem 'gmaps4rails'

# geocoder google
gem 'geocoder'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen'
  gem 'figaro'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'rack-attack', '6.7.0'

# Required by legacy Geocoder on Ruby 3.4+
gem 'csv'

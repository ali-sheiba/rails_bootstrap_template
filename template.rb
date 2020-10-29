# frozen_string_literal: true

# Inspired by [jumpstart](https://github.com/excid3/jumpstart)

require 'fileutils'
require 'shellwords'
require 'tmpdir'

RAILS_REQUIREMENT = '~> 6.0'

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
           "You are using #{rails_version}. Continue anyway?"
  exit 1 if no?(prompt)
end

def add_template_repository_to_source_path
  if __FILE__.match?(%r{\Ahttps?://})
    source_paths.unshift(tempdir = Dir.mktmpdir('rails-template-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      '--quiet',
      'https://github.com/ali-sheiba/rails_bootstrap_template',
      tempdir
    ].map(&:shellescape).join(' ')
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def assert_postgresql
  return if IO.read('Gemfile') =~ /^\s*gem ['"]pg['"]/

  raise Rails::Generators::Error,
        'This template requires PostgreSQL, '\
        'but the pg gem isn’t present in your Gemfile.'
end

def setup_gems
  setup_devise
  setup_annotate
  setup_rspec
end

def setup_devise
  generate 'devise:install'
  gsub_file 'config/initializers/devise.rb', /#\s(config\.secret_key)\s=\s(.*)/, 'config.secret_key = Rails.application.credentials.secret_key_base'
  gsub_file 'config/initializers/devise.rb', /#\s(config\.pepper)\s=\s(.*)/, "# config.pepper = ''"
  insert_into_file 'config/environments/development.rb', " \n config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }\n", before: /^end/

  generate :devise, 'User first_name:string last_name:string'

  # Set Rouets
  gsub_file 'config/routes.rb', 'devise_for :users' do
    <<~RUBY
      devise_for :users, path: 'auth'
    RUBY
  end
end

def setup_annotate
  generate 'annotate:install'
end

def setup_rspec
  generate 'rspec:install'
  directory 'spec'

  inject_into_file 'spec/rails_helper.rb', after: /\'spec_helper\'\n/ do
    <<-RUBY
require 'support/database_cleaner'
require 'support/factory_bot'
require 'support/shoulda_matchers'
    RUBY
  end
end

def setup_envs
  insert_into_file 'config/environments/development.rb', " \n config.action_mailer.delivery_method = :letter_opener\n", before: /^end/
  gsub_file 'config/environments/development.rb', "('tmp', 'caching-dev.txt')", "('tmp/caching-dev.txt')"
end

def setup_bootstrap
  run 'yarn add bootstrap jquery popper.js'
  run 'yarn add @fortawesome/fontawesome-free'

  insert_into_file 'config/webpack/environment.js', before: 'module.exports' do
    <<-RUBY
const webpack = require('webpack')

environment.plugins.append(
  'Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    Rails: '@rails/ujs'
  })
)

    RUBY
  end

  directory 'lib', force: true
  directory 'app', force: true
end

def setup_rubocop
  copy_file '.rubocop.yml'
  run 'rubocop -A -c .rubocop.yml -f q'
end

def add_gems
  gsub_file 'Gemfile' , /gem \'tzinfo-data\'.*\n/, ''
  gsub_file 'Gemfile' , /gem \'sass-rails\'.*\n/, ''
  gsub_file 'Gemfile' , /gem \'jbuilder\'.*\n/, ''
  gsub_file 'Gemfile' , /# .*\n/, ''

  gem 'devise'
  gem 'image_processing', '~> 1.2'
  gem 'pagy'
  gem 'ransack'
  gem 'redis', '~> 4.0'
  gem 'sidekiq'
  gem 'turbolinks', '~> 5'
  gem 'webpacker', '~> 4.0'

  gem_group :development, :test do
    gem 'dotenv-rails'
    gem 'factory_bot_rails'
    gem 'faker'
    gem 'pry-rails'
  end

  gem_group :development do
    gem 'annotate'
    gem 'letter_opener'
    gem 'rubocop',       require: false
    gem 'rubocop-rails', require: false
    gem 'rubocop-rspec', require: false
  end

  gem_group :test do
    gem 'database_cleaner'
    gem 'rspec-rails'
    gem 'shoulda-matchers'
    gem 'timecop'
  end
end

def finished!
  p '##############################################'
  p '#################### Done ####################'
  p '##############################################'
end

assert_minimum_rails_version
assert_postgresql
add_template_repository_to_source_path

add_gems

run  'gem install bundler'
run  'bundle install'

setup_gems
setup_envs

run 'bundle binstubs bundler --force'
run 'rails db:drop db:create db:migrate'

after_bundle do
  run "spring stop"
  setup_bootstrap
  setup_rubocop

  route "root to: 'pages#home'"

  git :init
  git add: '-A .'
  git commit: " -m 'Initial commit :star:'"

  finished!
end
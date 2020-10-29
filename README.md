# Rails template with Bootstrap 4.5.x

### How to use it:

```
rails new app \
  -d postgresql \
  --T \
  -m https://raw.githubusercontent.com/ali-sheiba/rails_bootstrap_template/master/template.rb
```

### Whats included?

The template will setup:

- devise
- pagy
- ransack
- redis
- sidekiq
- turbolinks
- webpacker

for testing and development:

- annotate
- database_cleaner
- dotenv-rails
- factory_bot_rails
- faker
- letter_opener
- pry-rails
- rspec-rails
- rubocop
- rubocop-rails
- rubocop-rspec
- shoulda-matchers
- timecop

### Bootstrap

the template will setup bootstrap with minimum requirement, devise bootstrap and it will provide scaffold generator using bootstrap also.

you can just run:

```
rails g scaffold post title:string content:text date:date

OR

rails g scaffold_controller post title:string content:text date:date
```

and it will take care of the views


### TODO:

Clean up the setup and test it in real project and document it.

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

# Added to deal with uninitialized constant Rake::DSL, but doesn't work on all systems... 
# Encourage use of 'bundle exec db:migrate' instead
#require 'rake/dsl_definition'   

require 'rake'

JULIE::Application.load_tasks

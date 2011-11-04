# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'rake/dsl_definition'   #Added to deal with uninitialized constant Rake::DSL

require 'rake'

JULIE::Application.load_tasks

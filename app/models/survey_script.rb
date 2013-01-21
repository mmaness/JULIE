# JULIE - an open-source survey design and administration framework
# Copyright (C) 2007-2013  Michael Maness
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


# Give the filepath in relation to the app/models/surveys filepath (assuming this file is in app/models/survenity)
def parse_and_compile(survey_filepath)
  compiler_filename = "#{File.dirname(__FILE__)}/survenity/kaywinnit_compiler.rb"
  load compiler_filename
  
  puts "\n\nSurvenityRuby, v0.1"
  puts ""
  puts "File path given: /app/models/surveys/#{survey_filepath.to_s}"
  
  path = File.dirname(__FILE__) + "/surveys/" + survey_filepath.to_s
  puts "The file was found, so parsing the input now using Citrus...\n"
  
  survey = parse_survey_file(path)
  
  puts "\nSurvey successfully parsed.  Progressing to compilation using Kaywinnit...", "", ""
  ActiveRecord::Base.logger.silence do  #Suppresses SQL output
    Kaywinnit::compile_survey(survey)
    
    puts "\n\nSurvey successfully compiled and bytecode stored in the database."
    
    puts "\nWill now add columns to RESPONSES table for each question..."
    MeiMei::CreateResponsesAndValuesTables.create
    puts "Columns successfully added."
    
    puts "\nWill now add columns to EXPERIMENT_RESPONSES table for each question..."
    MeiMei::CreateExperimentResponsesAndValuesTables.create
    puts "Columns successfully added."
    
    puts "\n\nSurvenityRuby done executing."
  end
  
end


module MeiMei
  
  class CreateResponsesAndValuesTables < ActiveRecord::Migration
    def self.create
      load File.dirname(__FILE__) + "/questions/question.rb"
      Question.all.each do
        |question|
        # Adds a column to the responses table if this question requires responses from the respondent
        if question.question_object.responses?
          begin
            add_column(:responses, question.question_name.to_s, :string)
            puts "  *Added column #{question.question_name} to RESPONSES table. (or the column already exists)"
          rescue Exception => e
            puts "  [WARN] An error was caught: #{e}"
          end
        else
          puts "  *Did not add column #{question.question_name}, this question does not allow for responses from the respondent"
        end
      end
    end
    
    def self.down
      raise 'Cannot execute down method for this migration, unsafe to delete response data that has been stored.'
    end
  end
  
  class CreateExperimentResponsesAndValuesTables < ActiveRecord::Migration
    def self.create
      load File.dirname(__FILE__) + "/questions/question.rb"
      
      experiment_alternatives = {}  #A hash which holds the alternative names (values) for each choice experiment (exp names are the keys)
      Experiment.all.each do
        |experiment|
        experiment_alternatives[experiment.name.to_s] = experiment.choice_exp_object.alternatives
      end
      
      Question.all.each do
        |question|
        if question.question_object.scenario?
          choice_column_name = question.question_object.get_choice_column_name
          begin
            add_column(:experiment_responses, choice_column_name, :string)
            puts "  *Added column #{choice_column_name} to the EXPERIMENT_RESPONSES tables."
          rescue Exception => e
            puts "  [WARN] An error was caught: #{e}"
          end
          
          begin
            add_column(:experiment_values, choice_column_name, :string)
            puts "  *Added column #{choice_column_name} to the EXPERIMENT_VALUES tables."
          rescue Exception => e
            puts "  [WARN] An error was caught: #{e}"
          end
          
          # Cycles through all the alternative names in the experiment associated with this scenario and
          # adds columns to the ExperimentResponses table
          question.question_object.get_column_names_by_alt(experiment_alternatives[question.question_object.choice_experiment_name.to_s]).each do
            |column_name|
            #Creates a column name in both the responses and values tables
            begin
              add_column(:experiment_responses, column_name, :string)
              puts "  *Added column #{column_name} to the EXPERIMENT_RESPONSES tables."
            rescue Exception => e
              puts "  [WARN] An error was caught: #{e}"
            end
            
            begin
              add_column(:experiment_values, column_name, :string)
              puts "  *Added column #{column_name} to the EXPERIMENT_VALUES tables."
            rescue Exception => e
              puts "  [WARN] An error was caught: #{e}"
            end
          end
        end
      end
    end
    
    def self.down
      raise 'Cannot execute down method for this migration, unsafe to delete response data that has been stored.'
    end
  end
  
end
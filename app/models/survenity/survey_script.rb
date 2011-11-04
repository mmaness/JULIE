

# Give the filepath in relation to the app/models/surveys filepath (assuming this file is in app/models/survenity)
def parse_and_compile(survey_filepath)
  compiler_filename = "#{File.dirname(__FILE__)}/../survenity/kaywinnit_compiler.rb"
  load compiler_filename
  
  puts "\n\nSurvenityRuby, v0.1"
  puts ""
  puts "File path given: /app/models/surveys/#{survey_filepath.to_s}"
  
  path = File.dirname(__FILE__) + "/../surveys/" + survey_filepath.to_s
  puts "The file was found, so parsing the input now using Citrus...\n"
  
  survey = parse_survey_file(path)
  
  puts "\nSurvey successfully parsed.  Progressing to compilation using Kaywinnit...", "", ""
  
  Kaywinnit::compile_survey(survey)
  
  puts "\n\nSurvey successfully compiled and bytecode stored in the database."
  
  puts "\nWill now add columns to Responses table for each question..."
  MeiMei::CreateResponsesTable.create
  puts "Columns successfully added."
  
  puts "\n\nSurvenityRuby done executing."
  
end


module MeiMei
  
  class CreateResponsesTable < ActiveRecord::Migration
    def self.create
      
      Question.all.each do
        |question|
        begin
          add_column(:responses, question.question_name.to_s, :string)
        rescue
          #column already exists with that name
        end
      end
    end
    
    def self.down
      raise 'Cannot execute down method for this migration, unsafe to delete response data that has been stored.'
    end
  end
  
end
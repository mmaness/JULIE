# JULIE - an open-source survey design and administration framework
# Copyright (C) 2007-2011  Michael Maness
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
          add_column(:responses, question.question_name.to_s, :string) unless question.dummy? || question.calculation? || question.link? || question.survey_settings?
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
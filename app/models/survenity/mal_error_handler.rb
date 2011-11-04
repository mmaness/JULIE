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


require 'treetop'

module Mal
  
  class ErrorHandler
    
    def self.misbehave 
      return "You aim to misbehave..."
    end
    
    def self.parse_with_treetop(file_path)
      Treetop.load("#{File.dirname(__FILE__)}/Survenity.treetop")
      parser = SurvenityParser.new
      parser.parse(File.open(file_path).read)
      
      puts misbehave + "  (Parse Error)\n\n"
      
      puts "Treetop Error Output:"
      
      puts parser.failure_reason
      puts ""
      
      # Prints out the lines around the parse error
      counter = 1
      File.open(file_path) do 
        |infile|
        while (line = infile.gets)
          if counter > parser.failure_line-3
            puts "#{counter}  " + line
          end
          
          if counter == parser.failure_line
            break
          end
          counter += 1
        end
      end
      
      (1..parser.failure_line.to_s.size+2).each {print " "}
      (1..parser.failure_column-1).each {print " "}
      print "^"
    end    
    
  end
  
  #################################
  # Error Classes                 #
  #################################
  
  # An error for the situation in which for an alternative,
  # two of the "set_levels_for" lines are for the same attribute
  class RepeatedAttributeForAlternativeError < StandardError
  end
  
  class ImproperResponseBoundsError < StandardError
    
  end
  
  class LevelsWithSameIndexError < StandardError
    
  end
  
  class QuestionNameRepeatedError < StandardError
    
  end
  
  class ChoiceExperimentNameRepeatedError < StandardError
    
  end
  
  class VariableNotFoundError < StandardError
    
  end
  
end
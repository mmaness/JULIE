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
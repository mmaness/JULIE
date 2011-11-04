# JULIE -- Software for Conducting Travel Surveys and Other Surveys
# Created by Michael Maness
# Copyright 2007 - 2010


module RubyJulie
  
  
  class Question
    
    attr_accessor :name, :question, :invalidInput, :section, :skip
    attr_accessor :before_calculations, :after_calculations, :default_message
    
    def initialize(name, question = "")
      @name = name
      @question = question
      @invalidInput = nil
      @default = nil
      @skip = true
    end
    
    # Returns true is the response given is a valid response to the question
    # Raises an exception by default... 
    # Each child should provide a correct implementation
    def isValid(answer)
      if (answer == nil || answer == '')
        @invalidInput = 'An answer was not provided'
        return false
      end
      return true
    end
    
    # Returns true if the question has static choice options, otherwise false
    def choices?
      return false
    end
    
    # Returns true if the question has static choice options and allows for multiple
    # answer to be chosen, otherwise false
    def multipleAnswer?
      return false
    end
    
    # Returns true if the question requires no input (dummy question)
    def dummy?
      return false
    end
    
    # Returns true if this is a place holder question used to populate the database
    def database?
      return false
    end
  
    # Used for checking to see if a Question object is passed into a QuestionList
    def question?
      return true
    end
    
    # Used to verify that a question is not a link. (for use in QuestionLists)
    def link?
      return false
    end
    
    # Used to verify if this question does calculations (is a Calculation object or descendent)
    def calculation?
      return false
    end
    
    # Used to verify if a question is skippable or not
    def skip?
      return @skip
    end
    
    def changeQuestion(text)
      if (text != nil)
        @question = text
      end
    end
    
    # Used to verify if this is a time question that asks for Hour and Minute data
    def timeHM?
      return false
    end
    
    # Used to verify if this is a day of the week question
    def timeWeek?
      return false
    end
    
    # Used to verify if this is a day and month question
    def timeDayMonth?
      return false
    end
    
    # Used to verify if this is a scenario from an SP Game
    def scenario?
      return false
    end
    
    # Sets a default answer (not required)
    def default_answer=(answer)
      @default = answer
    end
    
    # Returns the default answer
    def default_answer
      return @default
    end
    
  end
  
  class StaticChoice < Question
    
    attr_reader :choices, :values
    
    def initialize(name, question = "")
      super(name, question)
      @choices = []
      @values = []    #Provides alternate values to store in the database
      #Sets the string for the invalidInput
      @invalidInput = "An answer choice was chosen outside of the acceptable range of answers"
      @map = false
    end
    
    def choices?
      return true
    end
    
    #Boolean that notifies if an alternate set of values are mapping the choices
    def map?
      return @map
    end
    
    #Enables mapping the choices to an alternate set of values
    def enable_mapping_choices
      @map = true
    end
    
    # Add question choices (and mapped values to store in database)
    def addChoice(choiceText, choiceMap=nil)
      @choices.push(choiceText)
      if choiceMap != nil
        @values.push(choiceMap)
      else
        @values.push(nil)
      end
    end
    
    # Text for the choice with the selected index (zero-base)
    def editChoice(newChoiceText, index)
      if (index < 0 || index >= @choices.length)
        raise "Index out of bounds"
      end
      @choices[index-1] = newChoiceText
    end
  
    # Checks if the choice is within the index range (zero-based) of the question
    def isValid(index)
      if (super(index) == false)
       return false
      end
      if index == ""
        return false
      end
      #if (index.to_i < 0 || index.to_i >= @choices.length)
      #  return false
      #end
      return true
    end
    
  end
  
  class OpenQuestion < Question
  
    def initialize(name, question = "")
      super(name, question)
    end
   
  end
  
  class RangeQuestion < Question
    
  end
  
  class SingleChoice < StaticChoice
    
    def initialize(name, question = "")
      super(name, question)
    end
    
  end
  
  class MultipleAnswerQuestion < StaticChoice
    
    # Checks whether an array of indices are valid (zero-based)
    def isValid(index)
      if index == nil
        return true
      end
      
      index.each {
        |choice|
        if super.isValid(index) == false
          return false
        end
      }
      return true
    end
    
    def multipleAnswer?
      return true
    end
    
  end
  
  class YesNoQuestion < SingleChoice
    
    def initialize(name, question = "")
      super(name, question)
      self.addChoice("Yes")
      self.addChoice("No")
    end
    
  end
  
  class TrueFalseQuestion < SingleChoice
    
    def initialize(name, question = "")
      super(name, question)
      self.addChoice("True")
      self.addChoice("False")
    end
    
  end
  
  class MultipleChoice < SingleChoice
  
  end
  
  class Confirmation < YesNoQuestion
    
  end
  
  class OpenEndedQuestion < OpenQuestion
    
    def initialize(name, question = "")
      super(name, question)
      @invalidInput = "An answer was not provided"
    end
    
    def isValid(answer)
      # An answer must be provided
      if (answer == "" || answer == nil)
        return false
      end
      return true
    end
    
  end
  
    # An open-ended question with an text area for input
  class TextAreaQuestion < OpenEndedQuestion
    
    attr_accessor :height, :width
    
    def initialize(name, question = "")
      super(name, question)
      @no_answer = true
      @text_area = true
      @height = 5
      @width = 60
    end
    
    def text_area?
      return true
    end
    
    # Sets the size of the text area
    def set_size(height, width)
      if height.is_a?(Fixnum) && width.is_a?(Fixnum)
        @height = height
        @width = width
      else
        raise 'height or width parameter is not an integer (whole number)'
      end
    end
        
    def isValid(answer)
      if @no_answer
        return true
      else
        super
      end
    end
    
  end

  
  class NumberInputQuestion < OpenQuestion
    
    
    
  end
  
  class IntegerInputQuestion < NumberInputQuestion
    
    attr_accessor :lower_bound, :upper_bound
    
    def initialize(name, question = "")
      super(name, question)
    end
    
    def setLimits(lowerBound, upperBound = 1<<29)
      if lowerBound.class != Fixnum || upperBound.class != Fixnum
        raise "At least one bound is not an integer."
      end
      
      if lowerBound > upperBound
        raise "The lower bound parameter is greater than the upper bound parameter."
      end
      
      @lower_bound = lowerBound
      @upper_bound = upperBound
    end
    
    def isValid(answer, session)
      puts "answer: " + answer.to_s
      puts "default: " + @default.to_s
      if (answer == @default && answer != nil)
        return true
      end
      
      if (answer == "" || answer == nil || answer !~ /^-?\s*\d+\s*$/)
        @invalidInput = "Your answer must be a whole number."
        return false
      end
      
      if (answer.to_i > @upper_bound || answer.to_i < @lower_bound)
        @invalidInput = "Your answer must be between " + @lower_bound.to_s + " and " + @upper_bound.to_s + "."
        return false
      end
      
      return true
    end
    
  end
  
  class DecimalInputQuestion < NumberInputQuestion
    attr_accessor :lower_bound, :upper_bound
    
    def initialize(name, question = "")
      
      super(name, question)
      
    end
    
    def setLimits(lowerBound, upperBound = (1<<29).to_f)
      
      if ((lowerBound.class != Float && lowerBound.class != Fixnum) ||
           (upperBound.class != Float && upperBound.class != Fixnum))
        raise "At least one bound is not a float or integer."
      end
      
      if lowerBound > upperBound
        raise "The lower bound parameter is greater than the upper bound parameter."
      end
      
      @lower_bound = lowerBound
      @upper_bound = upperBound
      
    end
    
    def isValid(answer, session)
      if (answer == @default && answer != nil)
        return true
      end
      
      if (answer == "" || answer == nil || answer !~ /^-?\s*\d+(.\d+)?\s*$/)
        @invalidInput = "Your answer must be a valid number (whole or decimal)."
        return false
      end
      
      if (answer.to_f > @upper_bound || answer.to_f < @lower_bound)
        @invalidInput = "Your answer must be between " + @lower_bound.to_s + " and " + @upper_bound.to_s + "."
        return false
      end
      
      return true
    end
    
  end
  
  class CurrencyQuestion < DecimalInputQuestion
    
    def initialize(name, question = "")
      super(name, question)
    end
    
    def isValid(answer)
      if (answer == @default && answer != nil)
        return true
      end
      
      if (answer == nil || answer !~ /^\s*\d+(.\d{1,2})?\s*$/)
        @invalidInput = "Your answer must be a valid currency style number (example: 23.20, 0.57)."
        return false
      end
      
      return super(answer)
    end
    
  end
  
  class DummyQuestion < Question
    
    def dummy?
      return true
    end
    
    def isValid(answer)
      return true
    end
    
    def skip?
      return false
    end
    
  end
  
  class DatabaseQuestion < Question
    
    attr_accessor :value
    
    def initialize(name, value=nil)
      super(name, "")
      if value != nil
        @value = value
      end
    end
    
    def database?
      return true
    end
    
    def isValid(answer)
      return true
    end
    
    def skip?
      return false
    end
    
  end
  
  # Time of Day works with time in minutes after midnight
  class TimeOfDayQuestion < Question
    
    def initialize(name, question = "", lowerBound = 0, upperBound = 1440)
      if lowerBound.class != Fixnum || upperBound.class != Fixnum
        raise "At least one bound is not an integer."
      end
      
      if lowerBound > upperBound
        raise "The lower bound parameter is greater than the upper bound parameter."
      end
      
      super(name, question)
      @lowerBound = lowerBound
      @upperBound = upperBound
    end
    
    # Answer should be an array of size 2 with the 0-th entry representing hours and
    # the next entry representing minutes
    def isValid(answer)
      if (answer == @default && answer != nil)
        return true
      end
      
      if (answer == "" || answer == nil || answer !~ /^-?\s*\d+\s*$/)
        @invalidInput = "Your answer must be in minutes after midnight."
        return false
      end
      
      if (answer.to_i > @upperBound || answer.to_i < @lowerBound)
        @invalidInput = "Your answer must be between " + lowerBound.to_s + " and " + upperBound.to_s + "."
        return false
      end
      
      return true
    end
    
    #time1 and time2 should be entries containing hour, minutes in 24h time (midnight is 0h00)
    #returns the difference in minutes
    def self.timeDifference(time1, time2)
      minutes1 = time1[0] * 60 + time1[1]
      minutes2 = time2[0] * 60 + time2[1]
      
      if (minutes1 > minutes2)
        difference = 1440 - minutes1 + minutes2
      else
        difference = minutes2 - minutes1
      end
      
      return difference
    end
    
  end
  
  
  # A question which modifies the settings of the survey
  class SurveySettings < Question
    attr_accessor :survey_name, :description, :section
    
    def initialize(name)
      @name = name
    end
    
  end
  
  # A question which represents a block of code
  class CalculationBlock < Question
    
    def calculation?
      return true
    end
    
  end
  
  # A question which represents a scenario from a choice experiment
  class ScenarioQuestion < MultipleChoice
    
    attr_reader :choice_experiment_name, :pre_table_text, :post_table_text
    
    def initialize(name, choice_experiment_name)
      @name = name
      @choice_experiment_name = choice_experiment_name
    end
    
    
  end
  
  # An abstract object used to provide special support for situations in which logic is
  # required to change the question sequence
  #
  # Any class that inherits Link should implement the nextQuestion method
  class LogicLink < Question
    
    def link?
      return true
    end
    
    def dummy?
      return false
    end
    
    # Any class which inherits from Link must implement this method
    # Returns the question name of the next question in the question sequence according
    # to some logic which is determined from the object passed into the answer parameter
    def nextQuestion(answer)
      raise "Unimplemented Method (nextQuestion).  Object must create its own implementation of this method.\n"
    end
    
  end
  
  
  # A link which will always go to a particular question
  class SingleLink < LogicLink
    
    attr_accessor :name, :questionName
    
    def initialize(linkName, baseQuestionName)
      super(linkName)
      @questionName = baseQuestionName
    end
    
    def nextQuestion
      return @questionName
    end
  end
  
  # A link which redirects depending on which answer is given
  class MultipleChoiceLink < LogicLink
    
    attr_accessor :name, :base_question_name
    
    # linkName - the Name of the Link
    # base_question_name - the name of the question is the basis around the link's logic
    # defaultLink - the name of the question which is the default choice
    # answerLinkPairs - an array of hashes (Answer Choice => Linked Question Name)
    def initialize(name, base_question_name, defaultLink = "", *answerLinkPairs)
      super(name)
      @base_question_name = base_question_name
      @defaultLink = defaultLink
      @answerLinkPairs = Hash.new
      
      answerLinkPairs.each {|hash| @answerLinkPairs.merge(hash)}
    end
    
    def addAnswerLinkPair(answer, linkQuestionName)
      if @answerLinkPairs == nil
        @answerLinkPairs = {answer => linkQuestionName}
      else
        @answerLinkPairs.store(answer, linkQuestionName)
      end
    end
    
    def setDefaultLink(defaultLinkQuestionName)
      @defaultLink = defaultLinkQuestionName
    end
      
    def nextQuestion(answer)
      # Searches the hash array for an answer match and returns the link of the match, otherwise
      # returns the default link
      puts "Question" + @name.to_s
      if answer == nil
        return @defaultLink
      end
      @answerLinkPairs.each_pair { |choice, link|
        if choice.downcase == answer.downcase
          return link
        end
      }
      
      return @defaultLink
    end
  end
end
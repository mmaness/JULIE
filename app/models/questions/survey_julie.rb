# JULIE -- Software for Conducting Travel Surveys and Other Surveys
# Created by Michael Maness
# Copyright 2007 - 2010



load 'question.rb'
load 'calculation.rb'
load 'question_list.rb'

require 'singleton'

# Singleton QuestionList used for the SurveyRuby controller and view
class QList < QuestionList
  
  include Singleton
  attr_accessor :current_experiment, :current_alt, :current_variable, :current_level
  
  
  
end




#SurveyRuby DSL functions

#RP Question and Linking Functions

# Creates a multiple choice question
def multipleChoice(name)
  QList.instance.addQuestion(MultipleChoice.new(name))
end

# Creates a Yes/No Multiple Choice Question
def yesNo(name)
  QList.instance.addQuestion(YesNoQuestion.new(name))
end

# Creates a dummy (No Input) question
def dummy(name)
  QList.instance.addQuestion(DummyQuestion.new(name))
end

# Creates a database question which is used to populate the database
def databaseQuestion(name, value = nil)
  QList.instance.addQuestion(DatabaseQuestion.new(name, value))
end

# Creates a True/False Multiple Choice Question
def trueFalse(name)
  QList.instance.addQuestion(TrueFalseQuestion.new(name))
end

# Creates an Open Ended Question
def openEnded(name)
  QList.instance.addQuestion(OpenEndedQuestion.new(name))
end

# Creates an Integer Input Question
def integer(name)
  QList.instance.addQuestion(IntegerInputQuestion.new(name))
end

# Creates a Decimal Input Question
def decimal(name)
  QList.instance.addQuestion(DecimalInputQuestion.new(name))
end

# Creates a Currency Input Question
def currency(name)
  QList.instance.addQuestion(CurrencyQuestion.new(name))
end

# Creates a Time of Day (Hours & Minutes Input) Question
def timeOfDay(name)
  QList.instance.addQuestion(TimeOfDayQuestion.new(name))
end

# Creates a branching point that depends on a Multiple Choice Question
def multipleChoiceLink(name, baseQuestionName)
  QList.instance.addQuestion(MultipleChoiceLink.new(name, baseQuestionName))
end

# Maps an answer choice to a forwarding question
def addAnswerAndLink(answerChoice, linkedQuestionName)
  QList.instance.questionAt(QList.instance.size - 1).addAnswerLinkPair(answerChoice, linkedQuestionName)
end

# Maps all other answer choices to a forwarding question
def defaultLink(linkedQuestionName)
  QList.instance.questionAt(QList.instance.size - 1).setDefaultLink(linkedQuestionName)
end

# Creates a survey jump (jumps to the question with the given name)
def singleLink(name, linkedQuestionName)
  QList.instance.addQuestion(SingleLink.new(name, linkedQuestionName))
end

# Sets the next line of text for the last question created
def question(text)
  q = QList.instance.questionAt(QList.instance.size - 1)
  q.changeQuestion(q.question + "<br>" + text)
  #QList.instance.questionAt(QList.instance.size - 1).changeQuestion(text)
end

# Shorthand form of the question() method
def Q(text = '')
  question(text)
end

# Creates a label for the current section of the survey
def section(label)
  QList.instance.questionAt(QList.instance.size - 1).section = label 
end

# Sets the bounds of a Number Input Question (Currency, Integer, Decimal, etc.)
def bounds(lower = 0, upper = (1 << 29))
  QList.instance.questionAt(QList.instance.size - 1).setLimits(lower, upper)
end

# Adds an "I Don't Know" entry to the choice set and provides a default answer in this case
def addDefaultAnswer(answer)
  QList.instance.questionAt(QList.instance.size - 1).default_answer = answer
end

# Sets a question as unskippable
def noSkip
  QList.instance.questionAt(QList.instance.size - 1).skip = false
end

# Adds a choice to a Multiple Choice Question
def choice(value, text)
  #value variable is there for readibility reasons when typing out the code, unless map
  #option is enabled for the multiple choice question
  QList.instance.questionAt(QList.instance.size - 1).addChoice(text, value)
end

# Enables the mapping of the text in multiple choice questions to an alternate value
def mapChoices
  QList.instance.questionAt(QList.instance.size - 1).enable_mapping_choices
end


# Functions to describe Survey characteristics and custom variables

# Sets the name of the survey
def surveyName(name)
  QList.instance.name = name
end

# Sets a description for the survey
def setDescription(description = "")
  QList.instance.description = description
end


#def setVariable(var_name, data)
#  if (var_name !~ /^[a-zA-Z]([a-zA-Z]|[0-9])*$/)
#    raise 'setVariable requires a variable name with starts with a letter and contains only alphanumeric characters thereafter.'
#  end
#  
#  if (Qlist.instance.instance_variables.index("@#{var_name}") != nil)
#    QList.instance.instance_variable_set("@#{var_name}", data)
#  else
#    raise 'The survey already contains a variable with the given name, please choose a different variable name.'
#  end
#end




# Function for creating and modifying variables

def calculation(name)
  QList.instance.addQuestion(Calculation.new(name))
end

# Creates an instance variable with the given name and value
def variable(variable_name, operand)
  var = SetVariable.new(variable_name, operand)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

# Sets a variable equal to the value present in a database entry (or another value if equal to nil)
def database(variable_name, database_var_name, nil_check = true, set_nil_value_to = "nil")
  var = DatabaseVariable.new(variable_name, database_var_name, nil_check, set_nil_value_to)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

def addValueToDatabase(database_var_name, value)
  var = AddValueToDatabase.new(database_var_name, value)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

# Addition operation: Adds the operands up and sets a variable to that sum
def add(variable_name, *operands)
  var = Add.new(variable_name, *operands)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

# Subtraction operation: Subtracts the operands and sets a variable to that difference
def subtract(variable_name, *operands)
  var = Subtract.new(variable_name, *operands)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

# Multiplication operation: Multiplies the operands and sets a variable to that product
def multiply(variable_name, *operands)
  var = Multiply.new(variable_name, *operands)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

# Division operation: Divides the operands and sets a variable to that quotient
def divide(variable_name, *operands)
  var = Divide.new(variable_name, *operands)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

def absolute(variable_name, operand)
  var = AbsoluteValue.new(variable_name, operand)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

# Generate random number operation: Generates a random number between 0 and operand-1 and 
# sets that variable to that value
def random(variable_name, operand)
  var = RandomNumber.new(variable_name, operand)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

# Creates a conditional statement (switch statement / series of if's)
# variable_name is the name of the variable to set the result to
# conditional_var is the name of the variable which is the focus of the switch statement
# conditional_hash is a hash of the possible values of conditional_var along with the
#    result if true (e.g.  { 1=>10, 2=>20, 3=>30 })
def conditional(variable_name, conditional_var, conditional_hash)
  var = Conditional.new(variable_name, conditional_var, conditional_hash)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

# Creates a conditional statement (similar to switch statement / series of if's)
# where if the variable is between certain values, a particular result is stored
# variable_name is the name of the variable to set the result to
# conditional_var is the name of the variable which is the focus of the switch statement
# value_at_max_range is the value to be stored if the variable is less than the smallest key
#    in the hash
# conditional_hash is a hash of the possible values of conditional_var along with the
#    result if true (e.g.  { 10=>1, 20=>2, 30=>3 }, so if a variable = 25, then the result
#                       should be 2 since 25 is between 30 and 20)
# value_at_max_range is the value to be stored if the variable is greater than the largest key
#    in the hash
def rangeSwitch(variable_name, conditional_var, value_at_min_range, conditional_hash, value_at_max_range, nil_check = true, set_nil_value_to = "nil")
  var = RangeSwitch.new(variable_name, conditional_var, value_at_min_range, conditional_hash, value_at_max_range, nil_check, set_nil_value_to)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

# Truncates the given variable to the precision given (does not add trailing zeroes)
def precision(variable_name, operand)
  var = Decimal.new(variable_name, operand)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

# Truncates the given variable to an integer
def int(variable_name)
  var = ConvertToInteger.new(variable_name)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)  
end

# Converts the given variable into a float
def float(variable_name)
  var = ConvertToFloat.new(variable_name)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)  
end


# Rounds the given variable to the nearest n-th (where n is given)
def round(variable_name, operand)
  var = Round.new(variable_name, operand)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

def convertMinsToTime(variable_name, operand)
  var = ConvertMins.new(variable_name, operand)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end

def convertNumToCurrency(variable_name, operand)
  var = ConvertCurrency.new(variable_name, operand)
  QList.instance.questionAt(QList.instance.size - 1).add_command(var)
end


# SP/Choice Experiment Question Functions

# Creates a new choice experiment with the name given
def createChoiceGame(name)
  if (name == nil)
    raise 'A choice experiment (game) must have a name.'
  end
  
  if (QList.instance.find_experiment_by_name(name) != nil)
    raise "A choice experiment (game) with that name, #{name}, already exists."
  end
  
  QList.instance.add_experiment(name)
end

def scenarioQuestion(text, clear_text = false)
  if clear_text == true
    QList.instance.get_last_experiment.question = QList.instance.get_last_experiment.default_question
  end
  QList.instance.get_last_experiment.question = QList.instance.get_last_experiment.question + "<br>" + text
end

def scenarioAfterTableText(text, clear_text = false)
  if clear_text == true
    QList.instance.get_last_experiment.after_table_text = text
  else
    QList.instance.get_last_experiment.after_table_text = QList.instance.get_last_experiment.question + "<br>" + text
  end
end

# Creates a new alternative with the name given (number is not used, it's there for
# aesthetics and is an optional field)
def defineAlternative(name, number = -1)
  QList.instance.get_last_experiment.add_alternative(name)
end

# Creates a new attribute with the name given that will not have be displayed in the choice
# table, but will be an available option (number is not used, it's there for
# aesthetics and is an optional field)
def defineOption(name, number = -1)
  QList.instance.get_last_experiment.add_option(name)
end

def defineChoice(name, number = -1)
  defineOption(name, number)
end

def addAttributeLabel(name)
  QList.instance.get_last_experiment.add_attribute_label(name)
end

# Sets the number of scenarios to display to respondents
def numberOfScenarios(num)
  QList.instance.get_last_experiment.num_scenarios(num)
end

# Creates a variable with the given name
def createVariable(name, num_levels)
  QList.instance.get_last_experiment.add_variable(name, num_levels)
  QList.instance.current_variable = QList.instance.get_last_experiment.find_variable_by_name(name)
end

# Creates a level with the given index and value
def level(index, value)
  if (index < 0 || index >= QList.instance.current_variable.num_levels * QList.instance.current_variable.num_alt)
    raise "Index given (first argument) is out of bounds (less than 0 or greater than the number of levels for this variable minus one)"
  end
  
  QList.instance.current_variable.create_level(index, value)
  QList.instance.current_level = index
end

# Adds text to the last level created
def text(the_text)
  # Check to see if the level has no text
  if (QList.instance.current_variable.level_list[QList.instance.current_level].question == nil)
    QList.instance.current_variable.add_level_text(QList.instance.current_level, the_text)
  else
    QList.instance.current_variable.add_level_text(QList.instance.current_level, "<br>" + the_text)
  end
end

# Declare the alternative to use as the base when allocating levels to alternatives
def setLevelsForAlternative(alt_index)
  if alt_index < 0 || alt_index > QList.instance.get_last_experiment.alternatives.size - 1
    raise 'No alternative exists with the given index.'
  end
  QList.instance.current_alt = alt_index  
end

# Sets the attribute/variable levels for an alternative
def setLevel(variable_name, alt_level_index, var_level_index)
  if ( (variable = QList.instance.get_last_experiment.find_variable_by_name(variable_name)) == nil)
    raise "No variable with the name, #{variable_name} exist."
  end
  
  if (alt_level_index < 0 || alt_level_index > variable.num_levels)
    raise "The level index for the alternative is out of bounds."
  end
  if (var_level_index < 0 || alt_level_index > variable.num_levels)
    raise "The level index for the variable is out of bounds."
  end
    
  #QList.instance.get_last_experiment.set_level_for_alt(QList.instance.current_alt, alt_level_index, var_level_index)
  variable.set_level_for_alt(QList.instance.current_alt, alt_level_index, var_level_index)
end

# Adds a scenario to the experiment's design
def addScenario(scenario_index, *design_array)
  QList.instance.get_last_experiment.add_scenario(design_array)
end

# Allows the scenario design for a particular alternative be set to the scenario design of another alternative
def setScenarioToSame(alternative_index, set_to_index)
  QList.instance.get_last_experiment.set_scenario_to_same(alternative_index, set_to_index)
end

# Adds the scenarios from the choice experiment to the survey, can also add a method (block)
# that should be executed before a scenario is rendered by the controller and view
def addScenariosToSurvey(block = nil)
  num_scenarios = QList.instance.get_last_experiment.scenarios
  exp_name = QList.instance.get_last_experiment.name
  exp = QList.instance.get_last_experiment
  
  (1..num_scenarios).each do
    |num|
    question = QList.instance.addQuestion(Scenario.new("#{exp_name}_S#{num}", exp, exp.question))
    #Add the code block to the experiment so its executed before each scenario
    if block
      question.block = block
    end
  end
end

# Renames a choice experiment that is in the survey
def copyExperiment(old_exp_name, new_exp_name)
  old_exp = QList.instance.find_experiment_by_name(old_exp_name)
  if old_exp == nil
    raise "No experiment exists with the name #{old_exp_name}."
  end
  QList.instance.add_experiment(ChoiceExperiment.new(new_exp_name, old_exp))
end


class CreateSurveys < ActiveRecord::Migration
  
  def self.create
    begin
      #create_table QList.instance.name.intern do |t|
      create_table :surveys do |t|
        
      end
    rescue
      #puts "Table already exists"
    end
    
    begin
      add_column(:surveys, "SURVEY_ID", :string)
    rescue
      #puts 'Survey ID column already exists'
    end
    
    begin
      add_column(:surveys, "TIME", :string)
    rescue
      # puts 'Date column already exists
    end
    
    for index in (0..(QList.instance.size-1))    
      begin
        if (QList.instance.questionAt(index).dummy? == false && QList.instance.questionAt(index).calculation? == false  && QList.instance.questionAt(index).link? == false)
          add_column(:surveys, QList.instance.questionAt(index).name.intern, :string)
        end
      rescue
        #puts "rescued"
      end
    end
  end
  
  
  def self.create_column(name)
    #begin
    add_column :surveys, name, :string
    #rescue
    #  puts "add_column failed for #{name.to_s}"
    #end
  end
  
end

#load 'surveys/survey.qlist'
#load 'BWI.qlist'
#load 'surveys/BostonLA.qlist'
#load 'Taxes_and_Fees.qlist'
#load 'Price_and_Emissions.qlist'
#load 'test.qlist'
#load "surveys/HoT_495.qlist"


#load 'surveys/Taxes_and_Fees.qlist'
#CreateSurveys.create

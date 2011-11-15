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


load "#{File.dirname(__FILE__)}/mal_error_handler.rb"

##############################################
# Modules which are mixed into other modules #
##############################################

module QuestionType
  
  def text
    question_text = ""
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :question_text
        question_text += "\n" if question_text != ""
        question_text += trait.string.value
      end 
    }
    return question_text
  end
  
  # A warning that no question text appears for a question
  def no_text_warning
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :question_text
        return false
      end 
    }
    return true
  end
  
  def multiple_add_default_answer_warning
    num_defaults = 0
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      num_defaults += 1 if trait && trait.name == :add_default_answer
    }
    return (num_defaults > 1)
  end
  
  def before_calculations
    calculations = []
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :calculation
        calculations << trait if trait.before?
      end
    }
    return calculations
  end
  
  def after_calculations
    calculations = []
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :calculation
        calculations << trait if !trait.before?
      end
    }
    return calculations
  end
  
  #returns the default answer for this question or nil otherwise
  def default_answer
    default = nil
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :add_default_answer
        default = trait.answer.value
      end
    }
    return default
  end
  
  #returns the message to display for the choice to choose the default answer, or nil
  def default_message
    message = nil
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :add_default_answer
        message = trait.message.value if trait.message
      end
    }
    return default
  end
  
  #returns true if the question can be skipped 
  def skip?
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      return false if trait && trait.name == :no_skip
    }
    return true
  end
  
end

module ChoiceQuestion
  
  # Returns the choices (tree representation) associated with this question
  def choices
    choice_list = []
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :choice
        choice_list << trait
      end 
    }
    return choice_list
  end
  
  def same_choice_mapping_warning
    mapping_list = []
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :choice && trait.representation
        return true if mapping_list.index(trait.representation.value) != nil
        mapping_list << trait.representation.value
      end 
    }
    return false
  end
  
end


module NumberInputQuestion
  
  #returns the bounds associated with a question or an empty array if no bounds
  def bounds
    b = []
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :bounds
        b << trait.lower_bound
        b << trait.upper_bound if trait.upper_bound
        break
      end
    }
    return b
  end
  
  #returns true if there are more than one bound statement in the question block
  def multiple_bounds_warning
    num_bounds = 0
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      num_bounds += 1 if trait && trait.name == :bounds
    }
    return (num_bounds > 1)
  end
  
end


module Evaluatable
  
  def variable_exist?(variable, variable_list)
    puts Mal::ErrorHandler.misbehave
    puts ""
    raise Mal::VariableNotFoundError, "An identifier with the name #{variable.to_s} has not been initialized before.  All variables on the right hand side of assignments must be initialized prior to use." if variable_list.index(variable) == nil
  end
  
end


#################################################################
# Modules which are related to actual constructs in the grammar #
#################################################################

module SurveyFile
  
  include ChoiceQuestion
  # Returns the blocks in the file, deleting comments and whitespace
  # at the first order block level
  def clean_blocks
    b = []
    blocks.matches.each {
      |block| 
      b << block.matches[1] if block.matches[1].name    
      # Goes to the 2nd match because the first match should be matched to optional whitespace
    }
    return b
  end
    
  def name
    return :file
  end
  
end


module LoadFile
  
  def name
    return :load_file
  end
  
  # Returns the file name of the file to be loaded
  def file
    return string.value
  end
  
end


module Trait
  
  def trait_statement
    return trait if trait && trait.name
    return trait.trait_statement if trait
    return nil
  end
  
end


module MultipleQuestions
  
  # Returns the questions that make up this multiple question
  def questions
    # IMPLEMENT THIS
  end
  
  def name
    return :multiple_questions
  end
  
end


module SurveySetup
  
  def survey_name
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      return trait.string.value if trait && trait.name == :survey_name
    }
    return nil
  end
  
  def multiple_survey_names_warning
    num_names = 0
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      num_names += 1 if trait && trait.name == :survey_name
    }
    return (num_names > 1)
  end
  
  def description
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      return trait.string.value if trait && trait.name == :survey_description
    }
    return nil
  end
  
  def multiple_descriptions_warning
    num_descriptions = 0
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      num_descriptions += 1 if trait && trait.name == :survey_description
    }
    return (num_descriptions > 1)
  end
  
  def section
    section_text = ""
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :section
        section_text += "\n" if section_text != ""
        section_text += trait.string.value
      end 
    }
    if section_text == ""
      return nil
    end
    return section_text 
  end  
  
  def name
    return :survey_setup
  end
  
end



module MultipleChoiceQuestion
  include QuestionType
  include ChoiceQuestion
  
  def name
    return :multiple_choice_question
  end
  
end


module MultipleAnswerQuestion
  include QuestionType
  include ChoiceQuestion
  
  def name
    return :multiple_answer_question
  end
  
end


module YesNoQuestion
  include QuestionType
  
  def choices
    return ['No', 'Yes']
  end
  
  def choice_mappings
    return [0, 1]
  end
  
  def name
    return :yes_no_question
  end
  
end


module DummyQuestion
  include QuestionType
  
  def name
    return :dummy_question
  end
  
end


module TrueFalseQuestion
  include QuestionType
  
  def choices
    return ['False', 'True']
  end
  
  def choice_mappings
    return [0, 1]
  end
  
  def name
    return :true_false_question
  end
  
end

module OpenEndedQuestion
  include QuestionType
  
  def name
    return :open_ended_question
  end
  
end


module TextAreaQuestion
  include QuestionType
  
  def width
     traits.matches.each {
      |trait|
      trait = trait.trait_statement
      return trait.width if trait && trait.name == :text_area_size
    }
    return nil
  end
  
  def height
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      return trait.height if trait && trait.name == :text_area_size
    }
    return nil
  end
  
  def multiple_text_area_size_warning
    num_sizes = 0
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      num_sizes += 1 if trait && trait.name == :text_area_size
    }
    return (num_sizes > 1)
  end
  
  def name
    return :text_area_question
  end
  
end


module IntegerQuestion
  include QuestionType
  include NumberInputQuestion
  
  def name
    return :integer_question
  end
  
end


module DecimalQuestion
  include QuestionType
  include NumberInputQuestion
  
  def name
    return :decimal_question
  end
  
end


module CurrencyQuestion
  include QuestionType
  include NumberInputQuestion
  
  def name
    return :currency_question
  end
  
end


module TimeOfDayQuestion
  include QuestionType
  
  def name
    return :time_of_day_question
  end
  
end


module ScenarioQuestion
  include QuestionType
  include ChoiceQuestion
  
  def no_text_warning
    return false
  end
  
  #returns the text to be shown after the scenario table
  def post_table_text
    question_text = ""
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :post_table_text
        question_text += "\n" if question_text != ""
        question_text += trait.string.value
      end 
    }
    return question_text
  end
  
  #returns the text to be shown before the scenario table
  def pre_table_text
    question_text = ""
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :pre_table_text
        question_text += "\n" if question_text != ""
        question_text += trait.string.value
      end 
    }
    return question_text
  end
  
  def experiment_name
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :experiment_reference
        return trait.question_name.constant
      end
    }
    return nil
  end
  
  #warns if there are more than one reference experiment for this scenario question
  def multiple_experiments_warning
    num_experiments = 0
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :experiment_reference
        num_experiments += 1
      end
    }
    return (num_experiments > 1)
  end
  
  def name 
    return :scenario_question
  end
  
end


module MultipleBranch
  
  #returns the name of the question to based the branching on
  def reference_question
    return reference.question_name.constant.value
  end
  
  #returns a hash representing the branches with the key equal to the response
  #and the value being the question name to branch to if the associated resposne is given
  def branches
    b = {}
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      b[trait.response.value] = trait.constant.value if trait && trait.name == :branch
    }
    return b
  end
  
  #returns the question name of the default question to branch to
  def default
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      return trait.constant.value if trait && trait.name == :default_branch
    }
    return nil
  end
  
  def no_branches_warning
    return (branches == {} && default == nil)
  end
  
  def multiple_default_branch_warning
    num_defaults = 0
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      num_defaults += 1 if trait && trait.name == :default_branch
    }
    return (num_defaults > 1)
  end
  
  def name
    return :multiple_branch
  end
  
end


module SingleBranch
  
  def name
    return :single_branch
  end
  
end


module CalculationQuestion
  
  def name
    return :calculation_question
  end
  
end


module QuestionName
  
  def value
    return constant.value.to_s
  end
  
  def name
    return :question_name
  end
  
end


module QuestionText
  
  def name
    return :question_text
  end
  
end


module PreTableText
  
  def name
    return :pre_table_text
  end
  
end

module PostTableText
  
  def name
    return :post_table_text
  end
  
end


module Calculation
  
  #returns true if this calculation should be executed before the question is rendered
  def before?
    return true if time == "before"
    return false
  end
  
  def statements
    statement_list = []
    block.matches.each do
      |line|
      statement_list << line.statement if line.statement != nil
    end
    return statement_list
  end
  
  def name
    return :calculation
  end
  
end


module Section
  
  def name
    return :section
  end
  
end


module SurveyName
  
  def name
    return :survey_name
  end
  
end


module SurveyDescription
  
  def name
    return :survey_description
  end
  
end


module Bounds
  def name
    return :bounds
  end
  
end


module AddDefaultAnswer
  
  def name
    return :add_default_answer
  end
  
end


module NoSkip
  
  def name
    return :no_skip
  end
  
end


module Choice
  
  def name
    return :choice
  end
  
end


module TextAreaSize
  
  def name
    return :text_area_size
  end
  
end


module Reference
  
  def name
    return :reference
  end
  
end


module Branch
  
  def name
    return :branch
  end
  
end


module DefaultBranch
  
  def name
    return :default_branch
  end
  
end


module ExperimentReference
  
  def name
    return :experiment_reference
  end
  
end

module ChoiceExperiment
  include ChoiceQuestion
  
  def experiment_name
    return constant.value
  end
  
  #returns a list of the alternative names for the choice experiment or an empty list if none present
  def alternative_names
    alts = []
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :alternative
        alts << trait.alt_name.value
      end
    }
    return alts
  end
  
  #returns a list of the alternative for the choice experiment or an empty list if none present
  def alternatives
    alts = []
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :alternative
        alts << trait
      end
    }
    return alts
  end
  
  #returns the text to be shown after the scenario table
  def post_table_text
    question_text = ""
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :post_table_text
        question_text += "\n" if question_text != ""
        question_text += trait.string.value
      end
    }
    return question_text
  end
  
  #returns the text to be shown before the scenario table
  def pre_table_text
    question_text = ""
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :pre_table_text
        question_text += "\n" if question_text != ""
        question_text += trait.string.value
      end 
    }
    return question_text
  end
  
  #returns a list of attribute labels or an empty list if none given
  def attribute_labels
    labels = []
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :add_attribute
        labels << trait.label.label.value
      end
    }
    return labels
  end
  
  #returns a list of attribute match objects or an empty list if none given
  def attributes
    attribute_list = []
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :add_attribute
        attribute_list << trait
      end
    }
    return attribute_list
  end
  
  #returns a hash of levels for alternatives match objects or an empty list if none given
  #hash key: alternative name
  #hash value: level array
  def levels_for_alternatives
    level_hash = {}
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :alternative
        level_hash[trait.alternative_name] = trait.levels
      end
    }
    return level_hash
  end
  
  #returns a list of scenario design arrays or an empty list if none given
  def designs
    design_list = []
    traits.matches.each {
      |trait|
      trait = trait.trait_statement
      if trait && trait.name == :add_design
        design_list << trait.integer_array.value
      end
    }
    return design_list
    
  end
  
  def name
    return :choice_experiment
  end
  
end


module CreateExperiment
  
  def name
    return :create_experiment
  end
  
end


module Alternative
  
  #Returns a hash of levels
  #key: attribute name
  #value: levels for the attribute
  #Throws an error if an attribute name repeats
  def levels
    level_hash = {}
    captures[:set_levels].each do
      |line|
      if line.attribute != nil
        raise Mal::RepeatedAttributeForAlternativeError, "There is already an attribute with the name #{line.attribute.value} designated for this alternative." if level_hash.key?(line.attribute.value) 
        level_hash[line.attribute.value] = line.levels.value
      end
    end
    return level_hash
  end
  
  def alternative_name
    return alt_name.value
  end
  
  def name
    return :alternative
  end
  
end


module AttributeLabel
  
  def name
    return :attribute_label
  end
  
  def value
    return label.value
  end
  
end


module AddAttribute
  
  def attribute_name
    return constant.value
  end
  
  def levels
    level_list = []
    captures[:add_level].each do
      |line|
      level_list << line unless line.level == nil
    end
    return level_list
  end
  
  #Determines the maximum index of the levels for this attribute
  def max_level_index
    max_level_index = 0
    captures[:add_level].each do
      |line|
      max_level_index = line.level_index unless line.level == nil || line.level_index < max_level_index
    end
    return max_level_index
  end
  
  def label
    return captures[:attribute_label][0]
  end
  
  def multiple_labels_warning
    return captures[:attribute_label].length > 1
  end
  
  def levels_with_same_index_error
    indices = []
    levels.each do
      |lvl|
      if indices.include?(lvl.level_index)
        return true
      else
        indices << lvl.level_index
      end
    end
    return false
  end
  
  def name
    return :add_attribute
  end
  
end


module AddLevel
  
  def level_index
    return integer.value.to_i
  end
  
  def level_text
    level_text = ""
    captures[:level_text].each do
      |line|
      level_text += "\n" unless level_text == "" || line.string == nil
      level_text += line.string.value if line.string != nil
    end
    return level_text
  end
  
  def name
    return :add_level
  end
  
end

module LevelValue
  
  def value
    return val.value
  end
  
  def name
    return :level_value
  end
  
end


module LevelText
  
  def name
    return :level_text
  end
  
end


module SetLevelsForAlt
  
  def name
    return :set_levels_for_alt
  end
  
end


module SetLevels
  
  def name
    return :set_levels
  end
  
end


module AddDesign
  
  #returns the integer array of scenarios for the current design
  def design
    return integer_array.value
  end
  
  def name
    return :add_design
  end
  
end


module IntegerArray
  
  def value
    integers = []
    captures[:integer].each {|int| integers << int.to_i}
    return integers
  end
  
  def name
    return :integer_array
  end
  
end


module Statement
  
  def name
    return :statement
  end
  
end


module Assignment
  
  def name
    return :assignment
  end
  
end


# parenthesized expression
module ParenExpression
  
  def name
    return :paren_expression
  end
  
end


module EndParenExpression
  
  def name
    return :end_paren_expression
  end
  
end


module StringLiteral
  
  def name
    return :string_literal
  end
  
  def value
    return string.value
  end
  
end


module DoubleQuoteString
  
  def name
    return :double_quote_string
  end
  
  def value
    return string.to_s
  end
  
end


module SingleQuoteString
  
  def name
    return :single_quote_string
  end
  
  def value
    return string.to_s
  end
  
end


module ArrayLiteral
  
  def value
    list = []
    captures[:array_entry].each do
      |entry|
      list << entry.value
    end
    return list
  end
  
  def name
    return :array_literal
  end
  
end 


module Operation
  
  def name
    return :operation
  end
  
end


module Sum
  
  def name
    return :sum
  end
  
end


module Sequential
  
  def name
    return :sequential
  end
  
end

module Sequence
  
  def name
    return :sequence
  end
  
end


module Exponential
  
  def name
    return :exponential
  end
  
end


module Power
  
  def name
    return :power
  end
  
end


module Product
  
  def name
    return :product
  end
  
end


module Multiplicand
  
  def name
    return :multiplicand
  end
  
end

module Divisior
  
  def name
    return :divisor
  end
  
end


module IntegerDivisor
  
  def name
    return :integer_divisor
  end
  
end


module Modulo
  
  def name
    return :modulo
  end
  
end


module Addend
  
  def name
    return :addend
  end
  
end


module Subtrahend
  
  def name
    return :subtrahend
  end
  
end


module Function
  
  def name
    return :function
  end
  
end


module Parameters
  
  def name
    return :parameters
  end
  
end


module Types
  
  def name
    return :types
  end
  
end


module Number
  
  def name
    return :number
  end
  
end

module IntegerLiteral
  
  def name
    return :integer
  end
  
end


module DecimalLiteral
  
  def name
    return :decimal
  end
  
end


module VariableType
  
  def variable_name
    return identifier.to_sym
  end
  
  # Return true if this variable is a subscription
  def subscription?
    return true if captures[:array_index].length > 0
    return false
  end
  
  def indices
    index_list = []
    captures[:array_index].each do
      |i|
      index_list << i.value
    end
    return index_list
  end
  
  def value
    val = variable_name.to_s
    val += ":" if indices.length > 0
    indices.each do
      |index|
      val += '[' + index.to_s + ']'
    end
    return val.to_sym
  end
  
  def name
    return :variable
  end
  
end


module ArrayIndex
  
  def value
    return index_value.value
  end
  
  def name
    return :array_index
  end
  
end


module EndArrayIndex
  
  def name
    return :end_array_index
  end
  
end


module Constant
  
  def value
    return to_sym
  end
  
  def name
    return :constant
  end
  
end


module NullKeyword
  
  def value
    return :NULL
  end
  
  def null?
    return true
  end
  
  def name
    return :null_keyword
  end
  
end

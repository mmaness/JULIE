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


question_filename = "#{File.dirname(__FILE__)}/../questions/question.rb"
choice_exp_filename = "#{File.dirname(__FILE__)}/../questions/choice_experiment.rb"
parser_filename = "#{File.dirname(__FILE__)}/citrus_parser.rb"

load question_filename
load choice_exp_filename
load parser_filename

#Listing of constants
DEFAULT_TEXT_AREA_WIDTH = 60

module Kaywinnit
  
  # Takes a parsed survey (ParsedSurvey) and compiles it into 'meimei' bytecode
  def self.compile_survey(parsed_survey)
    
    puts "==================================="
    puts "Kaywinnit Compiler v0.1"
    puts "==================================="
    puts "\n\nRunning Kaywinnit compiler...", ""
    
    # Check the type of the parameter
    raise TypeError, "Expected an object of type ParsedSurvey in method compile_survey()." if parsed_survey.class != ParsedSurvey
    
    page_hash = {}  # hash of pages with values corresponding to the questions on that page
    page_list = []
    experiment_hash = {}
    question_names = []  #Array of questions which is used to ensure multiple questions don't have same name
    @@num_single_links = 0
    
    puts "Compiling the pages and questions of the survey:"
    puts "Number of pages = #{parsed_survey.pages.size}", ""
    parsed_survey.pages.each do
      |page_tree|
      puts "Translating page #{parsed_survey.pages.index(page_tree)+1}:"
      translate_page(page_tree, page_hash, page_list, question_names)
    end
    puts "Successful translated pages and questions into bytecode.", ""
    
    puts "Compiling the choice experiments of the survey:", ""
    puts "Number of experiments = #{parsed_survey.experiments.size}"
    parsed_survey.experiments.each do
      |exp_tree|
      translate_experiment(exp_tree, experiment_hash)
    end
    puts "Successful translated experiments into bytecode.", ""
    
    puts "Clearing the database of past pages, questions, and experiments..."
    #Put the survey in the database
    Page.delete_all
    Question.delete_all
    Experiment.delete_all
    
    puts "Clearing database successful.", ""
    page_count = 1
    
    puts "Adding pages to the database.", ""
    page_list.each do
      |page_name|
      questions = page_hash[page_name]
      print "  Adding page ##{page_count}, #{page_name}, to the database... "
      page_entry = Page.new
      page_entry.name = page_name
      page_entry.sequence_id = page_count
      page_count += 1
      
      # Add option to add text at a later time
      #page_entry.text = page_text[page_name]
      
      page_entry.save
      print "Page added to database successfully.\n"
      
      questions.each do
        |question|
        print "    Adding question #{question.name} to the question list... "
        question_entry = Question.new
        question_entry.question_name = question.name
        question_entry.question_object = question
        page_entry.questions << question_entry
        question_entry.save
        print "Question added to database successfully.\n"
      end
      
      page_entry.save
    end
    
    puts "\nAdding experiments to the database.", ""
    experiment_hash.each do
      |exp_name, exp_object|
      print "  Adding experiment #{exp_name} to the database... "
      exp = Experiment.new
      exp.name = exp_name
      exp.choice_exp_object = exp_object
      puts exp.choice_exp_object.class
      exp.save
      print "Experiment added to database successfully\n"
    end
    
    puts "\n\nKaywinnit successfully executed."
    return nil
  end
  
  def self.translate_page(parse_tree, page_hash, page_list, question_names)
    
    puts "  Page Name: #{parse_tree.question_name.value}" if parse_tree.question_name
    case parse_tree.name
      
    when :multiple_questions
      raise UnimplementedQuestionType, '"Multiple Questions" (MultipleQuestions) question type not implemented yet."'
      
      # WROTE THIS BEFORE I IMPLEMENTED TRUE SUPPORT FOR PAGES
      questions = []
      parse_tree.questions.each do
        |question_tree|
        check_for_repeating_question_names(question_tree, question_names)
        questions << translate_question(question_tree, page_hash)
      end
      page_hash[parse_tree.question_name.value] = questions
      
    when :single_branch
      questions = [translate_question(parse_tree, page_hash)]
      page_hash[questions[0].name] = questions
      page_list << questions[0].name
      
    else
      check_for_repeating_question_names(parse_tree, question_names)
      questions = [translate_question(parse_tree, page_hash)]
      page_hash[parse_tree.question_name.value] = questions
      page_list << parse_tree.question_name.value
    end
    
    return questions        
  end
  
  # A method to check if you are adding a question to the question list with the
  # same name as a preceding question
  def self.check_for_repeating_question_names(parse_tree, question_names)
    
    # Do not check question name of single branches
    return if parse_tree.name == :single_branch
    
    # Check that multiple questions don't have the same name
    if question_names.index(parse_tree.question_name.value)
      puts "A question with the name #{parse_tree.question_name.value} already exists in the survey."
      puts "The following questions were already in the survey before this question was to be added:"
      question_names.each_index do
        |index|
        puts "#{index}.  #{question_names[index]}"
      end
      raise Mal::QuestionNameRepeatedError
    else
      question_names << parse_tree.question_name.value
    end
    
  end
  
  # Takes a parse tree representation of a question and translates it into a
  # Ruby object
  def self.translate_question(parse_tree, page_hash)
    
    puts "    Question Name: #{parse_tree.question_name.value}" if parse_tree.question_name
    # Switch statement to deal with all the possible question types
    case parse_tree.name
    
    when :load_file
      raise UnimplementedOption, 'Loading files (load) is not implemented yet.'
    
    when :multiple_questions
      raise UnimplementedQuestionType, '"Multiple Questions" (MultipleQuestions) question type cannot be nested inside another MultpleQuestion question."'
    
    when :survey_setup
      puts "    Question Type: Survey Settings"
      question = RubyJulie::SurveySettings.new(parse_tree.question_name.value)
      question.survey_name = parse_tree.survey_name
      question.description = parse_tree.description
      question.section = parse_tree.section
      
      warn "    Warning: Question #{parse_tree.question_name.value} has multiple names ('survey_name' trait used multiple times).  Only the first name given will be used." if parse_tree.multiple_survey_names_warning
      warn "    Warning: Question #{parse_tree.question_name.value} has multiple descriptions ('description' trait used multiple times).  Only the first description given will be used." if parse_tree.multiple_descriptions_warning
    
    when :multiple_choice_question
      puts "    Question Type: Multiple Choice"
      question = RubyJulie::MultipleChoice.new(parse_tree.question_name.value)
      
      question_traits(question, parse_tree)
      
      choice_traits(question, parse_tree)    
      warn "    Warning: Question #{parse_tree.question_name.value} has more than one choice that maps to the same value. (for trait: 'choice text, value' , two or more function calls have the same \"value\" )." if parse_tree.same_choice_mapping_warning
      question_warnings(parse_tree)
    
    when :multiple_answer_question
      puts "    Question Type: Multiple Answer"
      question = RubyJulie::MultipleAnswerQuestion.new(parse_tree.question_name.value)
      
      question_traits(question, parse_tree)
      
      choice traits(question, parse_tree)    
      warn "    Warning: Question #{parse_tree.question_name.value} has more than one choice that maps to the same value. (for trait: 'choice text, value' , two or more function calls have the same \"value\" )." if parse_tree.same_choice_mapping_warning
      question_warnings(parse_tree)
      
    when :nested_choice_question
      puts "    Question Type: Nested Choice"
      raise UnimplementedQuestionType, '"Multiple Questions" (MultipleQuestions) question type not implemented yet."'
      question_traits(question, parse_tree)
      
      question_warnings(parse_tree)
    
    when :yes_no_question
      puts "    Question Type: Yes-No Question"
      question = RubyJulie::YesNoQuestion.new(parse_tree.question_name.value)
      question_traits(question, parse_tree)
      question_warnings(parse_tree)
    
    when :dummy_question
      puts "    Question Type: Dummy Question"
      question = RubyJulie::DummyQuestion.new(parse_tree.question_name.value)
      question_traits(question, parse_tree)
      question_warnings(parse_tree)
    
    when :true_false_question
      puts "    Question Type: True-False Question"
      question = RubyJulie::TrueFalseQuestion.new(parse_tree.question_name.value)
      question_traits(question, parse_tree)
      question_warnings(parse_tree)
    
    when :open_ended_question
      puts "    Question Type: Open-Ended Question"
      question = RubyJulie::OpenEndedQuestion.new(parse_tree.question_name.value)
      question_traits(question, parse_tree)
      question_warnings(parse_tree)
    
    when :text_area_question
      puts "    Question Type: Text-Area Question"
      question = RubyJulie::TextAreaQuestion.new(parse_tree.question_name.value)
      
      # set default width
      if parse_tree.width
        width = parse_tree.width.value.to_i
      else
        width = DEFAULT_TEXT_AREA_WIDTH
      end
      
      question.set_size(parse_tree.height.value.to_i, width) if parse_tree.height
      question_traits(question, parse_tree)
      question_warnings(parse_tree)
      warn "    Warning: Question #{parse_tree.question_name.value} has more than one 'text_area_size' trait" if parse_tree.multiple_text_area_size_warning
    
    when :integer_question
      puts "    Question Type: Integer Input Question"
      question = RubyJulie::IntegerInputQuestion.new(parse_tree.question_name.value)
      question_traits(question, parse_tree)
      bounds_trait(question, parse_tree)
      question_warnings(parse_tree)
    
    when :decimal_question
      puts "    Question Type: Decimal Input Question"
      question = RubyJulie::DecimalInputQuestion.new(parse_tree.question_name.value)
      question_traits(question, parse_tree)
      bounds_trait(question, parse_tree)
      question_warnings(parse_tree)
    
    when :currency_question
      puts "    Question Type: Currency Input Question"
      question = RubyJulie::CurrencyQuestion.new(parse_tree.question_name.value)
      question_traits(question, parse_tree)
      bounds_trait(question, parse_tree)
      question_warnings(parse_tree)
    
    when :time_of_day_question
      puts "    Question Type: Time-of-Day Question"
      question = RubyJulie::TimeOfDayQuestion.new(parse_tree.question_name.value)
      question_traits(question, parse_tree)
      bounds_trait(question, parse_tree)
      question_warnings(parse_tree)
    
    when :date_question
      puts "    Question Type: Date Question"
      raise UnimplementedQuestionType, '"Date" (Date) question type not implemented yet."'
    
    when :scenario_question
      puts "    Question Type: Scenario"
      question = RubyJulie::ScenarioQuestion.new(parse_tree.question_name.value, parse_tree.experiment_name.value)
      question_traits(question, parse_tree)
      choice_traits(question, parse_tree)
      question.pre_table_text = parse_tree.pre_table_text
      question.post_table_text = parse_tree.post_table_text
      question_warnings(parse_tree)
      
      warn "    Warning: Question #{parse_tree.question_name.value} is associated with more than one choice experiment (i.e. more than one 'reference' trait)." if parse_tree.multiple_experiments_warning
    
    when :multiple_branch
      puts "    Branch Type: Multiple Branch"
      question = RubyJulie::MultipleChoiceLink.new(parse_tree.question_name.value, parse_tree.reference_question)
      parse_tree.branches.each_key do
        |key|
        question.addAnswerLinkPair(key, parse_tree.branches[key]) 
      end
      question.setDefaultLink(parse_tree.default)
      
      warn "    Warning: Multiple Branch #{parse_tree.question_name.value} has no branches (i.e. no 'branch' traits)." if parse_tree.no_branches_warning
      warn "    Warning: Multiple Branch #{parse_tree.question_name.value} has more than one default branch ('default_branch' trait).  Only the first default branch given will be used." if parse_tree.multiple_default_branches_warning
    
    when :single_branch
      puts "    Branch Type: Single Branch"
      question = RubyJulie::SingleLink.new("single_link_#{@@num_single_links + 1}", parse_tree.question_name.value)
      @@num_single_links += 1
      
    when :calculation_question
      puts "    Question Type: Calculation Question"
      question = RubyJulie::CalculationBlock.new(parse_tree.question_name.value)
      question.before_calculations = "calculation before\n" 
      question.before_calculations += parse_tree.block.to_s + "\n"
      question.before_calculations += "end"
    
    when :choice_experiment
      puts "    Question Type: Choice Experiment"
      raise "A choice experiment is not a question, cannot parse it with this method, translate_question()."
    end
    
    puts "    Question Translation: Successful", ""
    return question
  end
  
  
  # Converts a parse tree representing a choice experiment into a Ruby object
  def self.translate_experiment(parse_tree, experiment_hash)
    puts "  Translating experiment #{parse_tree.name} into bytecode:"
    puts "  Experiment Name: #{parse_tree.name}"
    
    raise "A question is not a choice experiment, cannot parse this tree with this method, translate_experiment()." unless parse_tree.name == :choice_experiment
        
    #Check that no other experiments have the same name
    # Check that multiple questions don't have the same name
    if experiment_hash.keys.index(parse_tree.constant.value)
      puts "A choice experiment with the name #{parse_tree.constant.value} already exists in the survey."
      puts "The following choice experiments were already in the survey before this experiment was to be added:"
      experiment_hash.keys.each_index do
        |index|
        puts "#{index}.  #{experiment_hash.keys[index]}"
      end
      raise Mal::ChoiceExperimentNameRepeatedError
    end
    
    experiment = RubyJulie::ChoiceExperiment.new(parse_tree.constant.value)
    
    experiment.add_question_text(parse_tree.pre_table_text)
    experiment.after_table_text = parse_tree.post_table_text
  
    #Set the attribute labels
    parse_tree.attribute_labels.each do
      |label|
      experiment.add_attribute_label(label)
    end
    
    #Set the choice options
    parse_tree.choices.each do
      |choice|
      experiment.add_option(choice.text.value, choice.representation)
    end
    
    #Set the alternatives
    parse_tree.alternatives.each do
      |alt_match|
      experiment.add_alternative(alt_match.alternative_name)
    end
    
    #Create the attributes and set the attribute levels and corresponding text
    parse_tree.attributes.each do
      |attribute_match|
      experiment.add_variable(attribute_match.attribute_name, attribute_match.max_level_index + 1)    #Add one level to account for 0-base indexing
      attribute_match.levels.each do
        |level|
        experiment.find_variable_by_name(attribute_match.attribute_name).create_level(level.level_index, level.level_value.value)
        experiment.find_variable_by_name(attribute_match.attribute_name).add_level_text(level.level_index, level.level_text)
      end
    end
    
    #Set the levels for each alternative
    parse_tree.alternatives.each_index do
      |alt_index|
      levels = parse_tree.alternatives[alt_index].levels
      levels.each_key do
        |level_key|
        levels[level_key].each_index do
          |level_index|
          # Add a check here to make sure the level indicies are valid (within range of possible levels)
          experiment.find_variable_by_name(level_key).set_level_for_alt(alt_index, level_index, levels[level_key][level_index])
        end
      end
    end
    
    #Set the scenario designs
    parse_tree.designs.each do
      |design|
      experiment.add_scenario(design)
    end
    
    #NEED TO ADD CHECKS/WARNINGS TO CONFIRM THAT ALL LEVELS ARE USED IN THE DESIGNS
    
    parse_tree.attributes.each do
      |attribute|
      warn "  Warning: In Choice Experiment #{parse_tree.experiment_name.value}, attribute #{attribute.attribute_name} has more than one label (i.e. more than one 'attribute_label' trait).  Only the first label will be used" if attribute.multiple_labels_warning
      raise Mal::LevelsWithSameIndexError, "In Choice Experiment #{parse_tree.experiment_name}, attribute #{attribute.attribute_name} has more than one level with the same index (i.e. two or more 'add_level' traits have the same index parameter." if attribute.levels_with_same_index_error
    end 
    
    experiment_hash[parse_tree.constant.value] = experiment
    
    puts "  Experiment Translation: Successful", ""
    return experiment
  end
  
  # A methods which handles parsing question traits which are common.
  def self.question_traits(question, parse_tree)
    question.changeQuestion(parse_tree.text)  #Add question text
    question.before_calculations = ""
    parse_tree.before_calculations.each do
      |calc|
      question.before_calculations += calc.to_s + "\n"
    end
    question.after_calculations = ""
    parse_tree.after_calculations.each do
      |calc|
      question.after_calculations += calc.to_s + "\n"
    end
    question.skip = false if parse_tree.skip?
    question.default_answer = parse_tree.default_answer
    question.default_message = parse_tree.default_message
  end
  
  # A method for parsing bounds
  def self.bounds_trait(question, parse_tree)
    question.lower_bound = parse_tree.bounds[0].value unless parse_tree.bounds[0].null?
    question.upper_bound = parse_tree.bounds[1].value unless parse_tree.bounds[1] == nil || parse_tree.bounds[1].null?
    
    warn "    Warning: Question #{parse_tree.question_name.value} has more than one bounds trait.  Only the first one will be used" if parse_tree.multiple_bounds_warning
      
    #Check for number bounds which are in incorrect order
    if question.lower_bound.class != Symbol && question.upper_bound.class != Symbol
      raise Mal::ImproperResponseBoundsError, "The lower bound (#{question.lower_bound}) for question #{parse_tree.question_name.value} is larger than the upper bound (#{question.upper_bound})." if question.lower_bound > question.upper_bound
    end
  end
  
  def self.choice_traits(question, parse_tree)
    
    parse_tree.choices.each do
      |choice|
      if choice.representation
        question.addChoice(choice.text.value, choice.representation.value)
      else
        question.addChoice(choice.text.value)
      end
      
    end
    
  end
  
  # A method which handles the general question warnings 
  def self.question_warnings(parse_tree)
    warn "    Warning: Question #{parse_tree.question_name.value} has no question text (no 'text' or 't' trait)." if parse_tree.no_text_warning
    warn "    Warning: Question #{parse_tree.question_name.value} has multiple 'add_default_answer' traits.  Only one default answer will be used." if parse_tree.multiple_add_default_answer_warning
  end
    
end
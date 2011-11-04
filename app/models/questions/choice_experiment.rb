# JULIE -- Software for Conducting Travel Surveys and Other Surveys
# Created by Michael Maness
# Copyright 2007 - 2010


begin
  load 'question.rb'
rescue LoadError
  load '../questions/question.rb'      
end



module RubyJulie
    
  class ChoiceExperiment
    
    attr_accessor :name, :question, :after_table_text
    attr_reader :alternatives, :options, :variables, :scenarios, :exp_design, :display_level_value, :attribute_labels, :option_representations
    
    @@DEFAULT_QUESTION = ""
    
    def initialize(name, experiment = nil)
  
      @same_design = {}
  
      if experiment == nil
        @name = name
        @question = @@DEFAULT_QUESTION
        @after_table_text = ""
        @alternatives = []  # A list of the alternatives with levels
        @options = []       # A list of the alternatives with and without levels
        @variables = []
        @exp_design = []
        @scenarios = 1
        @attribute_labels = nil
        @option_representations = []
        @display_level_value = true
        @alternatives_finalized = false
      else
        @name = name
        @question = String.new(experiment.question)
        @alternatives = experiment.alternatives
        @options = experiment.options
        @variables = experiment.variables
        @exp_design = experiment.exp_design
        @scenarios = experiment.scenarios
        @attribute_labels = experiment.attribute_labels
        @option_representations = experiment.option_representations
        @display_level_value = true
        @alternatives_finalized = false
      end
      
      @pre_table_text = @question
    end
    
    def add_question_text(text)
      if (@question == "Please choose the best option from the choices below:")
        @question = ""
      end
      @question << text
      @pre_table_text = @question
    end
    
    def add_alternative(name)
      if @alternatives_finalized == true
        raise "Can not add any more alternatives.  The alternative set has been finalized."
      end
      
      if (@options.index(name) == nil)
        @alternatives << name
        return true
      else
        raise "An alternative with the given name (#{name}) already exists."
      end
    end
    
    
    def add_option(name, representation=nil)
      if (@options.index(name) == nil)
        @options << name
        if representation
          @option_representations << representation
        else
          @option_representations << @options.size-1                      
        end
        
        return true
      else
        raise "An choice/option with the given name (#{name}) already exists."
      end
    end
    
    def num_scenarios(num)
      if num <= 0
        raise 'Number of scenarios must be greater than zero.'
      end
      
      @scenarios = num
    end
    
    def find_alt_by_name(name)
      @alternatives.each do
        |alt|
        if alt.name == name
          return alt
        end
      end
      
      raise "An alternative with the given name (#{name}) does not exist."
    end
    
    def add_variable(name, num_levels)
      @alternatives_finalized = true
      
      @variables.each do
        |var|
        if var.name == name
          raise "A variable with the given name (#{name}) already exists."
        end
      end
      
      @variables << Variable.new(name, num_levels, @alternatives.size)
    end
    
    def find_variable_by_name(name)
      @variables.each do
        |var|
        if var.name == name
          return var
        end
      end
      
      raise "A variable with the given name (#{name}) does not exist."
    end
    
    # Adds the given array of level indexes to the list of possible scenarios (experimental design)
    def add_scenario(array)
      #TODO Add checks to ensure the array is within the bounds of the experiment
      @exp_design << array
    end
  
  
    # Allows the scenario design for a particular alternative be set to the scenario design of another alternative
    def set_scenario_to_same(alternative_index, set_to_index)  
      @same_design[alternative_index] = set_to_index
    end
    
    
    # Generates an array of scenario designs corresponding to each alternative
    def generate_scenario_design
      scenario = Array.new
      
      @alternatives.each_index do
        |alt|
        if @same_design[alt] == nil
          scenario << rand(@exp_design.size)
        else
          scenario << scenario[@same_design[alt]]
        end
      end
      
      return scenario
    end
    
    # Add a label for an attribute, this has no effect on the variables names, just used for
    # display purposes in the view/controller
    def add_attribute_label(label)
      if @attribute_labels == nil
        @attribute_labels = [label.to_s]
      else
        @attribute_labels << label.to_s
      end
    end
    
    # Returns the default question for a scenario
    def default_question
      @@DEFAULT_QUESTION
    end
    
  end
  
  
  class Variable
    
    attr_reader :name, :num_levels, :num_alt, :level_list, :levels
    
    def initialize(name, num_levels, num_alternatives)
      @name = name
      @num_levels = num_levels
      @level_list = Array.new(num_levels)
      @num_alt = num_alternatives
      
      #Creates a hash to represent the levels corresponding to each alternative
      @levels = Hash.new
      for index in 0..@num_alt-1 do
        @levels[index] = Array.new()
        #Create level objects for each entry in the array
        (1..num_levels).each do
          @levels[index] << Level.new
        end
      end
    end
    
    # Creates a level with the given index and assigns it the value given
    def create_level(level_index, value)
      @level_list[level_index] = Level.new
      @level_list[level_index].value = value
    end
    
    # Assigns a level (by index) the given text
    def add_level_text(level_index, text)
      #TODO Add Check for whether text is a String or not
      
      if @level_list[level_index].question == nil
        @level_list[level_index].question = text
      else
        @level_list[level_index].question << text
      end
      
    end
    
    # Sets the level for an alternative with the given index to a variable level from
    # the variable's level set
    def set_level_for_alt(alternative, alt_level_index, var_level_index)
      @levels[alternative][alt_level_index] = @level_list[var_level_index]
    end
    
    def all_levels_set?
      @levels.each do
        |lvl|
        if lvl.question == nil || lvl.value == nil
          return false
        end
      end
      
      return true
    end
    
  end
  
  class Level
    
    attr_accessor :question, :value
    
    def initialize
      @question = nil
      @value = nil
    end
    
    def to_s
      "Level: Value=>" + @value.to_s + ", text=>" + @question.to_s
    end
    
  end
  
  
  class Scenario < RubyJulie::MultipleChoice
    
    attr_accessor :experiment, :design, :block
    
    def initialize(name, experiment, question = "")
      super(name, question)
      @experiment = experiment
      @block = nil
    end
    
    def scenario?
      return true
    end
    
    def rows(design = nil)
      # Initializes the table that represents the list of attribute levels for the respondent to see
      table = Array.new(@experiment.variables.size)
      (0..table.size-1).each do
        |i|
        table[i] = Array.new(@experiment.alternatives.size)
      end
      
      
      alts = @experiment.alternatives
      
      # Determines which scenarios to run (which columns from experimental design array/chart)
      if design == nil
        design = @experiment.generate_scenario_design
      end
      #puts design.inspect
      puts "entire design... " + @experiment.exp_design.inspect.to_s
      puts "design... " + design.inspect.to_s
      puts @experiment.exp_design[design[0]].inspect
      puts @experiment.exp_design[design[1]].inspect
      puts @experiment.exp_design[design[2]].inspect
      #puts @experiment.exp_design[design[3]].inspect
      
      for i in (0..table.size-1) do
        #puts "@experiment.variables[#{i.to_s}]=" + @experiment.variables[i].to_s 
        for j in (0..alts.size-1) do
          level = @experiment.exp_design[design[j]][i]
          #puts @experiment.variables[i].levels.to_s
          #puts @experiment.variables[i].levels[j]
          #puts @experiment.exp_design[design[j]].inspect
          table[i][j] = @experiment.variables[i].levels[j][level].question
          #puts "row #{j.to_s}:" + @experiment.variables[i].levels[j].inspect.to_s
          #puts "I picked level #{level.to_s}"
          #puts i.to_s + ":" + j.to_s + "--" + table[i][j]
          #puts "Table:" + table.inspect
        end
      end
      
      @design = design
      
      return table
    end
    
    def alternatives
      return @experiment.alternatives
    end
    
    def choices
      return @experiment.options
    end
    
    def question
      return @experiment.question
    end
    
    def after_table_text
      return @experiment.after_table_text
    end
    
    def attribute_labels
      return @experiment.attribute_labels
    end
    
  end
end
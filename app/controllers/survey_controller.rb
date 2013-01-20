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

class SurveyController < ApplicationController
  
  #load 'questions/question.rb'
  #load 'questions/choice_experiment.rb'
  
  def instructions
    @name = "Survey Instructions"
    @description = ""
    
    #Initialize the Respondent, add entry to database
    if session[:count] == nil
      @respondent = Respondent.new
      @variable = Variable.new
      @variable.variable_hash = {}
      @respondent.variable = @variable
      @response = Response.new
      @respondent.response = @response
      @experiment_response = ExperimentResponse.new
      @respondent.experiment_response = @experiment_response
      @experiment_value = ExperimentValue.new
      @respondent.experiment_value = @experiment_value
      
      @respondent.save
      @variable.save
      @response.save
      @experiment_response.save
      @experiment_value.save
      
      session[:ID] = @respondent.id
      session[:response_ID] = @response.id
      session[:variable_ID] = @variable.id
      session[:experiment_response_ID] = @experiment_response.id
      session[:experiment_value_ID] = @experiment_value.id
      session[:count] = 1
      session[:ques_count] = 1   #Keeps track of the number of questions the user has seen
      session[:section] = ""     #Keeps track of the section to show to the user
      session[:sequence] = []
      session[:survey_name] = ""
      session[:survey_description] = ""
    end

  end
  
  def question
    load 'questions/question.rb'
    
    @page = Page.find_by_sequence_id(session[:count])
    @questionObject = @page.questions[0].question_object
    
    @respondent = Respondent.find_by_id(session[:ID])
    @variable = @respondent.variable
    @variable_hash = @variable.variable_hash
    puts "Variable_hash: #{@variable_hash}"
            
    if @questionObject.survey_settings?
      session[:survey_name] = @questionObject.survey_name if @questionObject.survey_name
      session[:survey_description] = @questionObject.description if @questionObject.description
      session[:section] = @questionObject.section if @questionObject.section
      
      return redirect_to :action => "check", :submit_count => session[:count]
    end
    
    @survey = Respondent.find_by_id(session[:ID]).response
    @dummy = @questionObject.dummy?
    
    @name = session[:survey_name]
    @description = session[:survey_description]
    @section = session[:section]    
    
    #Redirects to the scenario page if the question is a scenario
    if @questionObject.scenario?
      return redirect_to :action => "scenario"
    end
    
    #Redirects to check if the question is used to populate the database
    if @questionObject.database?
      redirect_to :action => "check", :submit_count => session[:count]
    end

    
    # Check to see if the "question" is a link, if so perform the logic required of that link
    # in order to determine the next question in the sequence
    # Otherwise, checks to see if the "question" is a set of calculations, if so executes the
    # calculations in that set
    if (@questionObject.link? == true)
      
      if @questionObject.class == RubyJulie::MultipleChoiceLink
        begin
          next_page_id = Question.find_by_question_name(@questionObject.nextQuestion(@survey.send(@questionObject.base_question_name))).page_id
        rescue NoMethodError => e
          raise NoMethodError, "In a MultipleBranch, the question name given for a possible branch, #{@questionObject.nextQuestion(@survey.send(@questionObject.base_question_name))}, does not exist in the survey.\n\nOriginal Exception Throw: " + e.to_s, e.backtrace
        end
        session[:count] = Page.find_by_id(next_page_id).sequence_id
      elsif @questionObject.class == RubyJulie::SingleLink
        session[:count] = Page.find_by_id(Question.find_by_question_name(@questionObject.nextQuestion()).page_id).sequence_id
      end
      
      #Perform pre-render calculations for the next question
      next_page = Page.find_by_sequence_id(session[:count])
      if next_page    #Check if the next question exists
        next_question = next_page.questions[0].question_object
        puts "Next Question, #{next_question.name}, Before Calculation: #{next_question.before_calculations.to_s}"
        load 'survenity/tam_expr_interpreter.rb' if next_question.before_calculations && next_question.before_calculations != ""
        Tam::run_interpreter(next_question.before_calculations, @variable_hash) if next_question.before_calculations && next_question.before_calculations != ""
        
        @variable.variable_hash = @variable_hash
        @variable.save
      end
      
      return redirect_to :action => "question"
      
    elsif (@questionObject.calculation?)
      return redirect_to :action => "check", :submit_count => session[:count]
      
    else
        
      @question = replaceVariablesInString(@questionObject.question, @survey)
      @question = replaceSymbolsInString(@question, @variable_hash)
      if @questionObject.choices?
        @choices = @questionObject.choices.map {|choice| replaceSymbolsInString(replaceVariablesInString(choice, @survey), @variable_hash)}
        
        #NEED TO THINK ABOUT HOW TO IMPLEMENT THIS
        #maps the choices to values if enabled
        #@values = @questionObject.values
        @values = @choices
      end
      
    end
    
    @count = session[:ques_count]  #the number of questions seen by the respondent
    @count_actual = session[:count]  #the current page id
    
    @sequence = session[:sequence]
    if session[:sequence].length <= 0
      @back = false
    else
      @back = true
    end
    
    #if @count == 1 && @count_actual == 1
    #  @back = false
    #elsif @count == 1 && (Page.first.questions[0].question_object.calculation? || Page.first.questions[0].question_object.survey_settings?)
    #  @back = false
    #else
    #  @back = true
    #end
  end
  
  
  # Method/Page to display SP scenario questions
  def scenario
    load 'questions/question.rb'
    load 'questions/choice_experiment.rb'
    
    if session[:count] == nil
      redirect_to :action => "survey"
    end
    
    @survey = Respondent.find_by_id(session[:ID]).response
    
    @page = Page.find_by_sequence_id(session[:count])
    return redirect_to :action => "results" unless @page   #If page isn't found, because sequence ID doesn't match, then the survey must have been completed
    
    @question = @page.questions[0].question_object
    
    @respondent = Respondent.find_by_id(session[:ID])
    @variable = @respondent.variable
    @variable_hash = @variable.variable_hash
    
    @name = session[:survey_name]
    @description = session[:survey_description]
    
    @count = session[:ques_count]
    @count_actual = session[:count]
    
    # Redirects to the default survey page if the current question isn't a scenario
    if @question.scenario? != true
      return redirect_to :action => "survey"
    end
    
    @experiment = Experiment.find_by_name(@question.choice_experiment_name).choice_exp_object
    
    @pre_table_text = @experiment.question if @experiment.question
    @pre_table_text += @question.pre_table_text
    @pre_table_text = replaceVariablesInString(@pre_table_text, @survey)
    @pre_table_text = replaceSymbolsInString(@pre_table_text, @variable_hash)
    
    @after_table_text = @experiment.after_table_text
    @after_table_text += @question.post_table_text if @question.post_table_text
    @after_table_text = replaceVariablesInString(@after_table_text, @survey)
    @after_table_text = replaceSymbolsInString(@after_table_text, @variable_hash)

    @choices = @experiment.options
    @choices += @question.choices if @question.choices
    attributes = @experiment.attribute_labels
    
    @alternatives = Array.new
    if attributes != nil
      @alternatives.push("")
    end
    @alternatives.concat(@experiment.alternatives)
    
    #PLACE HOLDER FOR CHANGES TO THE EXPERIMENTS WHICH WILL ALLOW FOR DESIGNS W/O REPLACEMENT
    designs_used = nil
    
    # Checks to see if the the rows should be the same as the last scenario shown
    if session[:rows_to_keep] == nil
      @rows, @value_table = @question.rows(@experiment, designs_used)
      index = 0
      
      @rows.each do
        |row|
        # Add attribute labels to the left column of the table
        if attributes != nil
          if attributes[index] == nil
            row.reverse!.push("").reverse!
          else
            row.reverse!.push(attributes[index]).reverse!
          end
        end
        
        index += 1
        row.map! {|cell| replaceSymbolsInString(replaceVariablesInString(cell, @survey), @variable_hash)}
      end
      
      #Set variables in the value_table to their current value
      @value_table.each_index do
        |row_index|
        @value_table[row_index].each_index do
          |col_index|
          value = @value_table[row_index][col_index]
          @value_table[row_index][col_index] = @variable_hash[value] if @variable_hash[value]
        end
      end
      
      session[:rows_to_keep] = @rows
      session[:design] = @question.design.join(" ")
      session[:value_table] = @value_table
    else
      @rows = session[:rows_to_keep]
      @values = session[:value_table]
    end
    
    if @count == 0 && @count_actual == 0
      @back = false
    else
      @back = true
    end
    
  end
  
  
  # Method/Page to check that an answer is valid (future function),
  # increment the survey questions, and redirect the user as needed
  #
  # FUTURE DEVELOPMENT: Need to change some of these session entries to params
  # entries since they are only needed temporarily, then I won't have to
  # keep track of setting them to nil
  def check
    load 'questions/question.rb'
    
    if session[:answer] == nil
      session[:answer] = Array.new
    end
    
    @survey = Respondent.find_by_id(session[:ID]).response

    @page = Page.find_by_sequence_id(session[:count])
    @question = @page.questions[0].question_object
    @respondent = Respondent.find_by_id(session[:ID])
    @variable = @respondent.variable
    @variable_hash = @variable.variable_hash
    
    # Checks to see if the submit button was pressed twice or more
    if params[:submit_count].to_i != session[:count].to_i
      puts "submit pressed twice!"
      if @question == nil
        redirect_to :action => "results"
      else
        redirect_to :action => "question"
      end
      return
    end
    
    if @question.class == RubyJulie::TimeOfDayQuestion
      params[:answer] = ([params[:hour], params[:minute]])
      params[:answer] = (params[:hour].to_i * 60 + params[:minute].to_i) % 720
      if params[:period] == "PM"
        params[:answer] += 720
      end
      params[:answer] = params[:answer].to_s
    end
    
    
    # Checks to see if the answer is valid or if the question was skipped
    if params[:skip] || @question.isValid(params[:answer], @variable_hash)
    
      session[:sequence].push(session[:count]) unless (@question.survey_settings? || @question.calculation?)  # Adds the question just answered to the sequence
      
      unless (@question.dummy? || @question.calculation? || @question.survey_settings?)
        # Inputs the value given into the Database
        if @question.scenario?
          # Some scenarios may allow for some added information to be stored in the database, this checks that
          if session[:entry_prefix] != nil
            response = session[:entry_prefix].to_s + session[:design] + " -- " + params[:answer]
            session[:entry_prefix] = nil
          else
            response = session[:design] + " -- " + params[:answer]
          end
          
          #Adds the experiment table's columns to the ExperimentResponses table
          columns = []
          values_columns = []
          (1..session[:rows_to_keep][0].length-1).each do
            |col|
            column = ""
            values_column = ""
            session[:rows_to_keep].each_index do
              |row|
              column << session[:rows_to_keep][row][col].to_s + '|'  #The current default delimiter is the pipe character
              values_column << session[:value_table][row][col-1].to_s + ';'
            end
            columns << column.chop  #Eliminates the trailing delimiter
            values_columns << values_column.chop  #Eliminates the trailing delimiter
          end
          
          experiment = Experiment.find_by_name(@question.choice_experiment_name.to_s).choice_exp_object
          column_names = @question.get_column_names_by_alt(experiment.alternatives)
          column_names.each_index do
            |index|
            column_name = column_names[index]
            ExperimentResponse.update(session[:experiment_response_ID], { column_name => columns[index]})
            ExperimentValue.update(session[:experiment_value_ID], { column_name => values_columns[index]})
          end
          
          #Adds the experiment table's values to the ExperimentValues table
          
          
        elsif @question.database?
          if @question.value.is_a?(Symbol)
            response = session[@question.value]
          else
            response = @question.value  
          end
        else
          response = params[:answer]
          response = '*SKIP*' if params[:skip]  #Checks if the question is skipped, then allocates the correct "skip" response
        end
        
        Response.update(session[:response_ID], { @question.name => response})
        
        
        @variable_hash[@question.name.to_sym] = response
        @variable_hash[@question.name.to_sym] = response.to_i if @question.answer_integer? && response != @question.default_answer
        @variable_hash[@question.name.to_sym] = response.to_f if @question.answer_decimal? && response != @question.default_answer
        
        session[:ques_count] += 1
      end
      
      #Perform post-render calculations for the current questions
      puts "After Calculations: #{@question.after_calculations.inspect}"
      load 'survenity/tam_expr_interpreter.rb' if @question.after_calculations && @question.after_calculations != "" 
      Tam::run_interpreter(@question.after_calculations, @variable_hash) if @question.after_calculations && @question.after_calculations != ""
      session[:count] += 1
    else
      flash[:notice] = @question.invalidInput
      if @question.scenario?    #This may need to be changed when the page system is fully implemented
        puts 'ROWSSSSSSSSSSSSSSSSSSSSSSSSS:' + session[:rows_to_keep].to_s
        redirect_to :action => "scenario"
      else
        redirect_to :action => "question"
      end
      return
    end
    
    session[:rows_to_keep] = nil
    session[:value_table] = nil
    
    if Page.find_by_sequence_id(session[:count]) == nil
      #Update the variable hash
      @variable.variable_hash = @variable_hash
      @variable.save
      redirect_to :action => "results" 
    else
      #Perform pre-render calculations for the next question
      next_page = Page.find_by_sequence_id(session[:count])
      if next_page    #Check if the next question exists
        next_question = next_page.questions[0].question_object
        puts "Next Question, #{next_question.name}, Before Calculation: #{next_question.before_calculations.to_s}"
        load 'survenity/tam_expr_interpreter.rb' if next_question.before_calculations && next_question.before_calculations != ""
        Tam::run_interpreter(next_question.before_calculations, @variable_hash) if next_question.before_calculations && next_question.before_calculations != ""
      end
      
      puts "#Variable Hash: #{@variable_hash}"
      #Update the variable hash
      @variable.variable_hash = @variable_hash
      @variable.save
      redirect_to :action => "question"
    end
  end
  
  
  def back
    load 'questions/question.rb'
    
    if session[:sequence].size > 0
      session[:count] = session[:sequence].pop
      
      question = Page.find_by_sequence_id(session[:count]).questions[0].question_object
      if !(question.dummy? || question.calculation? || question.link? || question.survey_settings?)
        session[:ques_count] -= 1
        #session[:sequence].pop if question.dummy?
      end
      
      while question.calculation? || question.link? || question.database? || question.survey_settings? do
        session[:count] = session[:sequence].pop
        question = Page.find_by_sequence_id(session[:count]).questions[0].question_object
      end
      
      
      # Handles the deletion of entries from the database
      begin
        #NOT IMPLEMENTING AT THE MOMENT
        #Response.find_by_respondent_id(session[:ID]).update(question.name, nil)
      rescue ActiveRecord::UnknownAttributeError
        # Don't throw exception to the browser
      end
    end
    
    redirect_to :action => "question"
  end
  
  
  
  def results
    @name = session[:survey_name]
    @description = session[:survey_description]
    @respondent = Respondent.find_by_id(session[:ID])
    @variable = @respondent.variable
  end

  
  #DEPRECATED METHOD... Should not use it
  #Given a question in survey_julie variable notation ( #(____) ) returns a new string
  #with the variables replaced with data from the database
  #Also takes the database model (survey)
  def replaceVariablesInString(oldString, survey)
    regex = /#\([a-zA-Z]\w*\)/
    matches = oldString.to_s.scan(regex)
    
    hash = Hash.new
    matches.each { 
      |variable|
      varName = getVariableName(variable)
      hash.store(variable, survey.send(varName))
    }
    
    newString = oldString.to_s
    hash.each { 
      |k,v|
      newString.gsub!(k.to_s,v.to_s)
    }
    
    return newString
  end
  
  
  #Given a question in survey_julie symbol notation ( :varname ) returns a new string
  #with the variables replaced with data from the variable hash
  def replaceSymbolsInString(oldString, variable_hash)
    regex = /:\([a-zA-Z]\w*\)/
    matches = oldString.scan(regex)
    
    hash = Hash.new
    matches.each { 
      |variable|
      varName = getVariableName(variable)
      if (variable_hash[varName.to_sym] == nil)
        hash.store(variable, "")
      else
        hash.store(variable, variable_hash[varName.to_sym])
      end
    }
    
    newString = oldString
    hash.each { 
      |k,v|
      newString.gsub!(k,v.to_s)
    }
    
    return newString
  end
  
  
  #Figures out the variable name between the '#(' and ')'
  def getVariableName(str)
    return str.match(/\w+/)[0]
  end
  
end

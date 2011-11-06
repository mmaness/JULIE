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

class SurveyController < ApplicationController
  
  def instructions
    @name = "Survey Instructions"
    @description = ""
    
    #Initialize the Respondent, add entry to database
    if session[:count] == nil
      @respondent = Respondent.new
      @variable_hash = Variable.new
      @variable_hash.variable_hash = {}
      @respondent.variable = @variable_hash
      @response = Response.new
      @respondent.response = @response
      
      @respondent.save
      @variable_hash.save
      @response.save
      
      session[:ID] = @respondent.id
      session[:count] = 1
      session[:ques_count] = 1   #Keeps track of the number of questions the user has seen
      session[:section] = ""     #Keeps track of the section to show to the user
      session[:sequence] = []
    end

  end
  
  def question
    
    load 'questions/question.rb'
    
    puts "page id: #{session[:count]}"
    @page = Page.find_by_sequence_id(session[:count])
    @questionObject = @page.questions[0].question_object
    
    @respondent = Respondent.find_by_id(session[:ID])
    @variable_hash = @respondent.variable
        
    if @questionObject.survey_settings?
      session[:survey_name] = @questionObject.survey_name if @questionObject.survey_name
      session[:survey_description] = @questionObject.survey_name if @questionObject.description
      session[:section] = @questionObject.section if @questionObject.section
      
      redirect_to :action => "check", :submit_count => session[:count]
      return
    end
    
    @survey = Respondent.find_by_id(session[:ID]).response
    @dummy = @questionObject.dummy?
    
    @name = session[:survey_name]
    @description = session[:survey_description]
    @section = session[:section]    
    
    #Redirects to the scenario page if the question is a scenario
    if @questionObject.scenario?
      redirect_to :action => "scenario"
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
        #puts "Question name: #{@questionObject.name}\nBase question name: " + @questionObject.baseQuestionName
        session[:count] = Page.find_by_id(Question.find_by_question_name(@questionObject.nextQuestion(@survey.send(@questionObject.base_question_name))).page_id).sequence_id
      elsif @questionObject.class == RubyJulie::SingleLink
        session[:count] = Page.find_by_id(Question.find_by_question_name(@questionObject.nextQuestion()).page_id).sequence_id
      end
      redirect_to :action => "question"
      
    elsif (@questionObject.calculation?)
      
      if (@questionObject.is_a?(RenameExperiment))
        @questionObject.execute(@questions)
      else
        puts @survey.class.to_s
        @questionObject.execute(session, @survey)
      end
      
      redirect_to :action => "check", :submit_count => session[:count]
      
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
    
    @count = session[:ques_count]
    @count_actual = session[:count]
    
    if @count == 1 && @count_actual == 1
      @back = false
    else
      @back = true
    end
  end
  
  
  # Method/Page to check that an answer is valid (future function),
  # increment the survey questions, and redirect the user as needed
  def check
    
    load 'questions/question.rb'
    
    if session[:answer] == nil
      session[:answer] = Array.new
    end
    
    @survey = Respondent.find_by_id(session[:ID]).response

    @page = Page.find_by_sequence_id(session[:count])
    @question = @page.questions[0].question_object
    
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
      #puts @question.isValid([params[:hour], params[:minute]])
      params[:answer] = ([params[:hour], params[:minute]])
      params[:answer] = (params[:hour].to_i * 60 + params[:minute].to_i) % 720
      if params[:period] == "PM"
        params[:answer] += 720
      end
      params[:answer] = params[:answer].to_s
    end    
    
    if(@question.isValid(params[:answer]))
    
      session[:sequence].push(session[:count])  # Adds the question just answered to the sequence
      
      unless (@question.dummy? || @question.calculation? || @question.survey_settings?)
        # Inputs the value given into the Database
        if @question.scenario?
          # Some scenarios may allow for some added information to be stored in the database, this checks that
          if session[:entry_prefix] != nil
            Response.update(session[:ID], { @question.name => session[:entry_prefix].to_s + session[:design] + " -- " + params[:answer]})
            session[:entry_prefix] = nil
          else
            Response.update(session[:ID], { @question.name => session[:design] + " -- " + params[:answer]})
          end
        elsif @question.database?
          if @question.value.is_a?(Symbol)
            Response.update(session[:ID], { @question.name => session[@question.value] })
          else
            Response.update(session[:ID], { @question.name => @question.value })  
          end
        else
          Response.update(session[:ID], { @question.name => params[:answer] })
        end
        session[:ques_count] += 1
      end
      session[:count] += 1
    else
      flash[:notice] = @question.invalidInput
      redirect_to :action => "question"
      return
    end
    
    
    if Page.find_by_sequence_id(session[:count]) == nil
      redirect_to :action => "results" 
    else
      redirect_to :action => "question" 
    end
  end
  
  
  def back
    load 'questions/question.rb'
    
    if session[:sequence].size > 0
      session[:count] = session[:sequence].pop
      
      question = Page.find_by_sequence_id(session[:count]).questions[0].question_object
      if !(question.dummy? || question.calculation? || question.link?)
        session[:ques_count] -= 1        
      end
      
      while question.calculation? || question.link? || question.database? do
        session[:count] = session[:sequence].pop
        question = @questions.questionAt(session[:count])
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
      newString.gsub!(k,v)
    }
    
    return newString
  end
  
  
  #Given a question in survey_julie symbol notation ( :varname ) returns a new string
  #with the variables replaced with data from the variable hash
  def replaceSymbolsInString(oldString, variable_hash)
    regex = /:[a-zA-Z]\w*/
    matches = oldString.scan(regex)
    
    hash = Hash.new
    matches.each { 
      |variable|
      varName = getVariableName(variable)
      if (variable_hash[varName.to_sym] == nil)
        hash.store(variable, variable)
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

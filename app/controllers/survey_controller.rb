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
    
    @name = session[:survey_name]
    @description = session[:survey_description]
    
    @page = Page.find_by_sequence_id(session[:count])
    @questionObject = @page.questions[0].question_object
    
    puts @questionObject.methods.sort
    #Redirects to the scenario page if the question is a scenario
    if @questionObject.scenario?
      redirect_to :action => "scenario"
    end
    
    #Redirects to check if the question is used to populate the database
    if @questionObject.database?
      redirect_to :action => "check", :submit_count => session[:count]
    end
    
    @survey = Respondent.find_by_id(session[:ID]).response
    @dummy = @questionObject.dummy?
    
    
    # Modifies the section header
    if @questionObject.section != nil
      @section = @questionObject.section
      session[:section] = @section
    else
      @section = session[:section]
    end
    
    
    # Check to see if the "question" is a link, if so perform the logic required of that link
    # in order to determine the next question in the sequence
    # Otherwise, checks to see if the "question" is a set of calculations, if so executes the
    # calculations in that set
    if (@questionObject.link? == true)
      
      if @questionObject.class == MultipleChoiceLink
        #puts "Question name: #{@questionObject.name}\nBase question name: " + @questionObject.baseQuestionName
        session[:count] = @questions.findIndexByName(@questionObject.nextQuestion(@survey.send(@questionObject.baseQuestionName)))
      elsif @questionObject.class == SingleLink
        session[:count] = @questions.findIndexByName(@questionObject.nextQuestion())
      end
      redirect_to :action => "survey"
      
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
      @question = replaceSymbolsInString(@question)
      @choices = @questionObject.choices
      if @choices != nil
        #REIMPLEMENT THIS!
        #@choices = @choices.map {|choice| replaceSymbolsInString(replaceVariablesInString(choice, @survey))}
        
        #maps the choices to values if enabled
        if @questionObject.map?
          @values = @questionObject.values
        else
          @values = @choices
        end
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
  
  # NEED TO IMPLEMENT
  def replaceVariablesInString(text, response_table)
    return text
  end
  
  def replaceSymbolsInString(text)
    return text
  end
  
end

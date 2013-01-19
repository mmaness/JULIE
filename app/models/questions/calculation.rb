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


# A "question" object which allows for operations on user-specified variables
class Calculation < RubyJulie::Question

  def initialize(name)
    super(name)
    @commands = []
  end
  
  def calculation?
    return true
  end
  
  def add_command(command)
    if command.is_a?(Command)
      @commands << command
    else
      raise 'A command was not provided to the add_command() method.'
    end
  end
  
  def execute(session_hash, database = nil)
    if (session_hash.is_a?(Hash) == false && session_hash.is_a?(CGI::Session) == false)
      raise "A hash (or session) must be provided to the execute() method."
    end
    
    @database = database
    @commands.each do
      |command| 
      #puts command.to_s
      if command.is_a?(DatabaseVariable) || command.is_a?(SetValueInDatabase)
        command.execute(session_hash, database)
      else
        command.execute(session_hash)
      end
    end
  end
  
  def isValid(answer = nil)
    return true
  end
  
  def responses?
    return false
  end
  
end

class Command
  @@keywords = [:id, :count, :surveyID, :ques_count, :design, :answer, :section, :sequence]
  
  def initialize(variable, *operands)
    if(variable.is_a?(Symbol))
      
      if @@keywords.include?(variable)
        raise 'The variable must not be one of the following keywords -- :id, :count, :surveyID, :ques_count, :design, :answer.'
      end
      @variable = variable
    else
      raise 'The variable must have be in the form ":varname" where varname is an alphanumeric string that starts with a letter'
    end
    
    @operands = []
    operands.each do
      |operand|
      if (operand.is_a?(Symbol) || operand.is_a?(Fixnum) || operand.is_a?(Float))
        @operands << operand
      else
        raise 'All operands must be in the form ":varname" or be a number.'
      end
    end 
  end
  
  # Performs the operation
  def execute(session_hash)
    raise "execute() not implemented for this object (Command)."
  end
  
  def to_s
    string = "(" + @variable.to_s
    @operands.each {|o| string = string + "," + o.to_s}
    string = string + ")"
    return string
  end
  
end


# Initializes a variable
class SetVariable < Command
  
  def initialize(variable, operand)
    if(variable.is_a?(Symbol))
      
      if @@keywords.include?(variable)
        raise 'The variable must not be one of the following keywords -- :id, :count, :surveyID, :ques_count, :design, :answer.'
      end
      @variable = variable
    else
      raise 'The variable must have be in the form ":varname" where varname is an alphanumeric string that starts with a letter'
    end
    
    if (operand.is_a?(Symbol) || operand.is_a?(Fixnum) || operand.is_a?(Float) || operand.is_a?(String))
        @operands = [operand]
    else
        raise 'All operands must have be in the form ":varname" or be a number.'
    end 
  end
  
  def execute(session_hash)
    if @operands[0].is_a?(Symbol)
      if session_hash[@operands[0]] == nil
        raise "Variable, :#{@variable.to_s}, can not be set to nil (i.e. the operand, :#{@operand[0].to_s}, does not exists."
      end
      
      session_hash[@variable] = session_hash[@operands[0]]
      return session_hash[@operands[0]]
    else
      session_hash[@variable] = @operands[0]
      return @operands[0]
    end
  end
  
  def to_s
    return "SetVariable" + super.to_s
  end
  
end


# Adds an array of operands
class Add < Command
  
  def execute(session_hash)
    result = 0
    @operands.each do
      |operand|
      if operand.is_a?(Symbol)
        result = result + session_hash[operand]
      else
        result = result + operand
      end
    end
    
    session_hash[@variable] = result
    return result
  end

  def to_s
    return "Add" + super.to_s
  end
  
end

# Subtracts an array of operands
class Subtract < Command
  
  def execute(session_hash)
    first = @operands[0]
    result = 0
    
    if first.is_a?(Symbol)
      result = 2 * session_hash[first]
    else
      result = 2 * first
    end
    
    @operands.each do
      |operand|
      if operand.is_a?(Symbol)
        result = result - session_hash[operand]
      else
        result = result - operand
      end
    end
    
    session_hash[@variable] = result
    return result
  end

  def to_s
    return "Subtract" + super.to_s
  end
  
end

# Multiplies an array of operands
class Multiply < Command
  
  def execute(session_hash)
    result = 1
    @operands.each do
      |operand|
      #puts "operand: " + operand.to_s + ":" + session_hash[operand].class.to_s
      if operand.is_a?(Symbol)
        result = result * session_hash[operand]
      else
        result = result * operand
      end
    end
    
    session_hash[@variable] = result
    return result
  end
  
  def to_s
    return "Multiply" + super.to_s
  end
  
end

# Divides an array of operands
class Divide < Command
  
  def execute(session_hash)
    first = @operands[0]
    result = 0
    
    if first.is_a?(Symbol)
      result = session_hash[first]
    else
      result = first
    end
    
    @operands.each do
      |operand|
      if (operand != @operands[0])
        if operand.is_a?(Symbol)
          result = result / session_hash[operand]
        else
          result = result / operand
        end
      end
    end
    
    session_hash[@variable] = result
    return result
  end
  
  def to_s
    return "Divide" + super.to_s
  end
  
end

# Returns a random number between 0 and the first operand minus 1
class RandomNumber < Command
  
  def execute(session_hash)
    result = rand(@operands[0]) 
    
    session_hash[@variable] = result
    return result
  end
  
  def to_s
    return "Random" + super.to_s
  end
  
end

# Truncates a variable (e.g. 5.02 => 5, OR 6.76 => 6)
class ConvertToInteger < Command
  
  def execute(session_hash)
    session_hash[@variable] = session_hash[@variable].to_i
    
    return session_hash[@variable]
  end
  
end

class ConvertToFloat < Command
  
  def execute(session_hash)
    session_hash[@variable] = session_hash[@variable].to_f
    
    return session_hash[@variable]
  end
  
end

# Rounds a number to the nearest k-th (e.g. if k=10, then 6 to the nearest 10th is 10)
class Round < Command
  
  def execute(session_hash)
    x = session_hash[@variable]
    y = @operands[0]
    
    session_hash[@variable] = ((x/y).to_i + (x%y/y.to_f).round) * y    
  end
  
end

# Converts minutes into H:MM AM/PM format
class ConvertMins < Command
  
  def execute(session_hash)
    time = session_hash[@operands[0]]
    time = time % 1440
    
    if time >= 720
      period = "PM"
    else
      period = "AM"
    end
  
    time = time % 720
    if time < 60
      hour = 12
    else
      hour = time / 60
    end
  
    mins = time % 60
    if mins < 10
      mins = "0" + mins.to_s
    else
      mins = mins.to_s
    end
  
    session_hash[@variable] = hour.to_s + ":" + mins + " " + period
  end

  
end

# Converts a float or integer into currency format "D.CC"
class ConvertCurrency < Command
  
  def execute(session_hash)
    num = session_hash[@operands[0]].to_f
    cents = num.abs * 100 % 100
    dollars = num.to_i
    cents = cents.to_i
    if cents < 10
      cents = "0" + cents.to_s
    else
      cents = cents.to_s
    end
    
    session_hash[@variable] = dollars.to_s + "." + cents
  end
  
end


# Truncates a float to the precision given (does not add trailing zeroes)
class Decimal < Command
  
  def execute(session_hash)
    x = session_hash[@variable]
    y = @operands[0]
    
    session_hash[@variable] = (x * (10**y)).to_i / (10**y).to_f
  end
  
end


# Creates a switch like statement (an if-else series)
class Conditional < Command
  
  def initialize(variable, conditional_var, conditional_hash)
    super(variable, 1)
    @conditional = conditional_var
    @conditional_hash = conditional_hash
  end
  
  def execute(session_hash)
    result = @conditional_hash[session_hash[@conditional]]
    
    if result == nil
      raise "No result corresponding to #{session_hash[@conditional].to_s} exists in the hash."
    else
      if result.is_a?(Symbol)
          session_hash[@variable] = session_hash[result]
      else
          session_hash[@variable] = result
      end
      
    end
    
    return result
  end
  
  def to_s
    s = "SetVariable(" + @variable.to_s + "," + @conditional.to_s
    @conditional_hash.each {|entry| s = s + "," + entry.to_s}
    s = s + ")"
    return s
  end
  
end


# Creates a switch-like statement but between certain ranges instead of at specific values
class RangeSwitch < Command
  
  def initialize(variable, conditional_var, value_at_min_range, conditional_hash, value_at_max_range, nil_check = true, set_nil_value_to = "nil")
    super(variable, 1)
    @conditional = conditional_var
    @conditional_hash = conditional_hash
    @value_at_min = value_at_min_range
    @value_at_max = value_at_max_range
    @nil_check = nil_check
    @nil_value = set_nil_value_to
  end
  
  def execute(session_hash)
    value = session_hash[@conditional].to_f
    
    # Check to see if 
    if value == nil
      if @nil_check
        raise "No result corresponding to #{session_hash[@conditional].to_s} exists in the hash."
      else
        if @set_nil_value_to.is_a?(Symbol)
          session_hash[@variable] = session_hash[@nil_value]
        else
          session_hash[@variable] = @nil_value
        end
      end
    else      
      
      range = @conditional_hash.keys.sort
      
      if value < range[0]
        result = @value_at_min
      else
        (1..range.size-1).each {
          |i|
          if value < range[i]
            result = @conditional_hash[range[i-1]]
            break
          end
        }
      end
      
      if value >= range.sort.pop
        result = @value_at_max
      end
      
      if result.is_a?(Symbol)
        session_hash[@variable] = session_hash[result]
      else
        session_hash[@variable] = result
      end
      
      return result
    end
    
  end
  
  def to_s
    s = "Range(" + @variable.to_s + "," + @conditional.to_s
    @conditional_hash.each {|entry| s = s + "," + entry.to_s}
    s = s + ")"
    return s
  end
  
end


# Sets a variable to a value located in the database
class DatabaseVariable < Command
  
  def initialize(variable_name, database_variable, nil_check = true, set_nil_value_to = "nil")
    super(variable_name, -1)
    @database_var = database_variable.to_s
    @nil_check = nil_check
    @nil_value = set_nil_value_to
  end
  
  def execute(session_hash, database)
    result = database.send(@database_var.to_s)
    if result == nil
      if @nil_check
        raise "A column in the database named \"#{@database_var}\" does not exists or has no entry."
      else
        session_hash[@variable] = @nil_value
      end
    else
      session_hash[@variable] = result
    end
    
    return result
  end
  
  def to_s
    return "DatabaseVariable(" + @variable.to_s + "," + @database_var.to_s + ")"
  end
  
end

# Sets a database entry to the given value (does not create a new column)
class SetValueInDatabase < Command
  
  def initialize(variable, operand)
    if(variable.is_a?(String))
      if @@keywords.include?(variable)
        raise 'The variable must not be one of the following keywords -- :id, :count, :surveyID, :ques_count, :design, :answer.'
      end
      @variable = variable
    else
      raise 'The variable must be in the form "varname" where varname is an alphanumeric string that starts with a letter'
    end
    
    if (operand.is_a?(Symbol) || operand.is_a?(Fixnum) || operand.is_a?(Float) || operand.is_a?(String))
        @operand = operand
    else
        raise 'The operand must have be in the form ":varname" or be a number.'
    end 
  end
  
  def execute(session_hash, database)
    if database.has_attribute?(@variable) == false
      raise "A column in the database named \"#{@variable}\" does not exists or has no entry."
    elsif(@operand.is_a?(Symbol))
      # CHANGE THIS SO I CAN USE THE SURVEY DATABASE DIRECTLY (database variable)
      Survey.update(session_hash[:ID], { @variable => session_hash[@operand] })
    else
      Survey.update(session_hash[:ID], { @variable => @operand })
    end
  end
  
  def to_s
    return "SetValueInDatabase(" + @variable.to_s + "," + @operand.to_s + ")"
  end
  
end


# Create a new column (if necessary) and sets a database entry to the given value
class AddValueToDatabase < SetValueInDatabase
  
  def execute(session_hash, database)
    
    if database.has_attribute?(@variable) == false
      load 'survey_julie.rb'
      CreateSurveys.create_column(@variable.to_s)
    end
    
    if(@operand.is_a?(Symbol))
      # CHANGE THIS SO I CAN USE THE SURVEY DATABASE DIRECTLY (database variable)
      puts "operand:" + session_hash[@operand].to_s
      Survey.update(session_hash[:ID], { @variable => session_hash[@operand] })
    else
      puts "operand:" + @operand.to_s
      Survey.update(session_hash[:ID], { @variable => @operand })
    end
  end
  
end



# Renames an experiment
class RenameExperiment < Calculation
  
  def initialize(name, new_exp_name, original_exp_name, new_question = nil)
    super(name)
    @new_name = new_exp_name
    @old_name = original_exp_name
    @new_question = new_question
  end
  
  def execute(question_list)
    old_exp = question_list.find_experiment_by_name(@old_name)
    if old_exp == nil
      raise "No experiment exists with the name #{@old_name}."
    end
    
    old_exp.name = @new_name
    
    if @new_question != nil
      #puts "new question is... " + @new_question.to_s
      old_exp.question = @new_question
    end
    
    question_list.add_experiment(old_exp)
  end

end
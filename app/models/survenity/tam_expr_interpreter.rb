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


require 'citrus'

module Tam
  
  # In the future, should refactor this code to place all of it inside a singleton
  # object.  That way, I can keep the state and not have to keep passing it between functions
  
  def self.run_interpreter(statement_block, variable_hash)
    #Parse the calculations
    load "#{File.dirname(__FILE__)}/survenity_nodes.rb"
    Citrus.load "#{File.dirname(__FILE__)}/Survenity"
    match = SurvenityGrammar.parse(statement_block.strip, :root => 'calculation')  #Need to remove trailing whitespace, calculation rule does not handle trailing whitespace
    statement_list = match.statements
    
    statement_list.each do
      |statement|
      puts statement.inspect
      match_list = []
      list_tree(statement, match_list)
      puts match_list.inspect
      interpret_statement(match_list, variable_hash)
    end
    
    return variable_hash
  end
  
  # Turns a Citrus::Match into a list of all matches within the parent match
  # Turns a parse tree into a sequential list
  def self.list_tree(match, list)
    if match.matches.length == 0
      return
    else
      list << match if match.name
      match.matches.each {|x| list_tree(x, list)}
    end
  end
  
  #Iterative interpreter
  def self.interpret_statement(match_list, variable_hash)
    
    #Turns the statement list into a stack
    match_list.reverse!
    statement = match_list.pop

    #Determines what type of statement the match list corresponds to
    if assignment?(match_list.last)
      match_list.pop
      return assignment(match_list, variable_hash, statement)
    else
      return expression(match_list, variable_hash, statement)
    end
    
  end
  
  # Determines if a statement is an assignment
  def self.assignment?(parse_tree)
    return parse_tree.name == :assignment
  end
  
  # Handles assignment statements
  def self.assignment(match_list, variable_hash, statement)
    
    identifier = match_list.pop.value
    variable_hash[identifier] = expression(match_list, variable_hash, statement)
    return variable_hash[identifier]
  end
  
  # Handles expression statements
  def self.expression(match_list, variable_hash, statement)
    
    first_expr = match_list.pop
    
    if first_expr.name == :paren_expression
      value = expression(match_list, variable_hash, statement)
    else
      if variable?(first_expr)
        value = variable_initialized_and_non_null(first_expr, match_list, variable_hash, statement)
      else
        value = convert_literal(first_expr, match_list)
      end
    end
    
    puts "value: #{value}"
    
    while match_list.size > 0
      current_expr = match_list.pop    #current expression
      
      break if current_expr.name == :end_paren_expression
      break if current_expr.name == :end_array_index
      
      case value_type(value, statement)
        
      when :string
        raise "From statement:\n#{Statement}\nNo operations supported for strings in the current release."
      
      when :number
        case current_expr.name
          
        when :addend
          value = add_numbers(value, match_list, variable_hash, statement)
          
        when :subtrahend
          value = subtract_numbers(value, match_list, variable_hash, statement)
          
        when :multiplicand
          value = multiply_numbers(value, match_list, variable_hash, statement)
          
        when :integer_divisor
          value = integer_divide_numbers(value, match_list, variable_hash, statement)
          
        when :divisor
          value = divide_numbers(value, match_list, variable_hash, statement)
          
        when :modulo
          value = mod_numbers(value, match_list, variable_hash, statement)
          
        when :power
          value = power_numbers(value, match_list, variable_hash, statement)
          
        when :sequence
          value = sequence_numbers(value, match_list, variable_hash, statement)
          
        else
          puts "operation: #{current_expr.name}"
          raise UnsupportedOperationError, "Unsupported operation error: In statement,\n#{statement.to_s}\nAn operation is unsupported by this interpreter."
          
        end
        
      when :list
        raise "From statement:\n#{statement.to_s}\nNo operations supported for lists in the current release."
      
      end
    end
    
    return value
  end
  
  #helper method to get the value of the next operand
  def self.get_next_operand(match_list, variable_hash, statement)
    right_operand = match_list.pop
    if right_operand.name == :paren_expression
      right_operand = expression(match_list, variable_hash, statement)
    elsif right_operand.value.is_a?(Symbol)
      right_operand = variable_initialized_and_non_null(right_operand, match_list, variable_hash, statement) 
    else
      right_operand = convert_literal(right_operand, match_list)
    end
    
    return right_operand
  end
  
  # helper method which determines the type of a literal
  # inside_array parameter is there to handle cases when an array is created inside another array
  def self.convert_literal(literal_expression, match_list, inside_array=false)
    case literal_expression.name
          
    when :integer
      value = literal_expression.value.to_i
    when :decimal
      value = literal_expression.value.to_f
    when :string
      value = literal_expression.value
    when :double_quote_string
      value = literal_expression.value
    when :single_quote_string
      value = literal_expression.value
    when :array_literal
      match_list.pop if inside_array
      value = []
      literal_expression.captures[:array_entry].each do
        |entry|
        value << convert_literal(entry, match_list, true)
        match_list.pop    # Remove the entries from the match list corresponding to the elements in the list
      end
    end
    
    return value
  end
  
  def self.add_numbers(left_operand, match_list, variable_hash, statement)
    right_operand = get_next_operand(match_list, variable_hash, statement)
    
    raise UnsupportedTypeError, "In statement:\n#{statement.to_s}\n#{right_operand.to_s} does not have a right operand that is a number." if value_type(right_operand, statement) != :number
    return left_operand + right_operand
  end
  
  def self.subtract_numbers(left_operand, match_list, variable_hash, statement)
    right_operand = get_next_operand(match_list, variable_hash, statement)
       
    raise UnsupportedTypeError, "In statement:\n#{statement.to_s}\n#{right_operand.to_s} does not have a right operand that is a number." if value_type(right_operand, statement) != :number
    return left_operand - right_operand
  end
  
  def self.multiply_numbers(left_operand, match_list, variable_hash, statement)
    right_operand = get_next_operand(match_list, variable_hash, statement)
       
    raise UnsupportedTypeError, "In statement:\n#{statement.to_s}\n#{right_operand.to_s} does not have a right operand that is a number." if value_type(right_operand, statement) != :number
    return left_operand * right_operand
  end
  
  def self.divide_numbers(left_operand, match_list, variable_hash, statement)
    right_operand = get_next_operand(match_list, variable_hash, statement)
       
    raise UnsupportedTypeError, "In statement:\n#{statement.to_s}\n#{right_operand.to_s} does not have a right operand that is a number." if value_type(right_operand, statement) != :number
    return left_operand / right_operand.to_f
  end
  
  def self.integer_divide_numbers(left_operand, match_list, variable_hash, statement)
    right_operand = get_next_operand(match_list, variable_hash, statement)
       
    raise UnsupportedTypeError, "In statement:\n#{statement.to_s}\n#{right_operand.to_s} does not have a right operand that is a number." if value_type(right_operand, statement) != :number
    return left_operand / right_operand
  end
  
  def self.mod_numbers(left_operand, match_list, variable_hash, statement)
    right_operand = get_next_operand(match_list, variable_hash, statement)
       
    raise UnsupportedTypeError, "In statement:\n#{statement.to_s}\n#{right_operand.to_s} does not have a right operand that is a number." if value_type(right_operand, statement) != :number
    return left_operand % right_operand
  end
  
  def self.power_numbers(left_operand, match_list, variable_hash, statement)
    right_operand = get_next_operand(match_list, variable_hash, statement)
       
    raise UnsupportedTypeError, "In statement:\n#{statement.to_s}\n#{right_operand.to_s} does not have a right operand that is a number." if value_type(right_operand, statement) != :number
    return left_operand ** right_operand
  end
  
  def self.sequence_numbers(left_operand, match_list, variable_hash, statement)
    right_operand = get_next_operand(match_list, variable_hash, statement)
       
    raise UnsupportedTypeError, "In statement:\n#{statement.to_s}\n#{right_operand.to_s} does not have a right operand that is a number." if value_type(right_operand, statement) != :number
    raise "For sequential operation, both operands must be integers\nIn statement: #{statement}" unless right_operand.is_a?(Fixnum) && left_operand.is_a?(Fixnum)
    
    list = []
    if left_operand > right_operand
      (right_operand..left_operand).each {|i| list << i}
    else
      (left_operand..right_operand).each {|i| list << i}
    end
    
    return list
  end
  
  #Checks to see if an expression corresponds to a variable
  def self.variable?(expr)
    return expr.name == :variable || expr.name == :constant
  end
  
  #Checks a hash of variable name-variable value pairs to see
  #if a variable has been initialized in that hash 
  def self.variable_exist?(expr, variable_hash)
    puts "Country: #{expr.value.inspect}"
    return variable_hash.has_key?(expr.value) if expr.name == :constant
    return variable_hash.has_key?(expr.variable_name)
  end
  
  #Checks variable list to see if a the value associated with a
  #variable is null.  Possible that the variable might not even
  #have a key in the variable_hash
  def self.variable_null?(expr, variable_hash)
    return (variable_hash[expr.value] == nil) if expr.name == :constant
    return variable_hash[expr.variable_name] == nil
  end
  
  #Determines the type of a value (e.g. string, list, number)
  def self.value_type(value, statement)
    return :string if value.is_a?(String)
    return :number if value.is_a?(Fixnum)
    return :number if value.is_a?(Float)
    return :list if value.is_a?(Array)
    
    # Raise an error if value is not a supported type
    raise UnsupportedTypeError, "A value, #{value.to_s}, is of an unsupported type.  It's type is #{value.class}\nIn statement: #{statement.to_s}"
  end
  
  # Returns the value associated with an identifier if that identifier has been initialized and has a value associated with it in the variable hash
  def self.variable_initialized_and_non_null(expression, match_list, variable_hash, statement)
    if variable?(expression)
      raise VariableNotInitializedError, "A variable, named #{expression.value.to_s}, in an expression is not initialized.\nExpression: #{statement.to_s}" unless variable_exist?(expression, variable_hash)
      raise NullVariableError, "Variable #{expression.value.to_s} has a value of null.  It must have a value to be used in an element in an expression.\nExpression:\n#{statement.to_s}" if variable_null?(expression, variable_hash)
      return get_identifier_value(expression, match_list, variable_hash, statement)
    end
    
    return nil
  end
  
  #Returns the value associated with an identifier if that identifier has been initialized in the variable hash
  def self.variable_initialized(expression, match_list, variable_hash, statement)
    if variable?(expression)
      raise VariableNotInitializedError, "A variable, named #{expression.value.to_s}, in an expression is not initialized.\nExpression:\n#{statement.to_s}" if variable_exist?(expression, variable_hash)
      return get_identifier_value(expression, match_list, variable_hash, statement)
    end
    
    return nil
  end
  
  #Helper method to get the value associated with an identifier
  def self.get_identifier_value(expr, match_list, variable_hash, statement)
    return variable_hash[expr.value] unless expr.subscription?
    
    # Handles lists (identifiers which correspond to subscriptions)
    pointer = variable_hash[expr.variable_name]
    expr.indices.each do
      |index|
      match_list.pop
      pointer = pointer[expression(match_list,variable_hash,statement)]
    end
    return pointer
  end
  
  #An error where an identifier is used on the right-hand side of an assignment before it has been initialized
  class VariableNotInitializedError < StandardError
    
  end
  
  #An error where the value associated with an identifier is null where it needs to have a value
  class NullVariableError < StandardError
    
  end
  
  #An error for when the type associated with a value is not supported
  class UnsupportedTypeError < StandardError
    
  end
  
  # Error for when an operation is not supported in the interpreter
  class UnsupportedOperationError < StandardError
    
  end
  
end
  
   

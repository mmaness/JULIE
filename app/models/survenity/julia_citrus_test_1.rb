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
load 'survenity_nodes.rb'
load 'kaywinnit_compiler.rb'
#load 'mal_error_handler.rb'
load 'citrus_parser.rb'
load 'tam_expr_interpreter.rb'

def print_tree(match)
  if match.matches.length == 0
    return
  else
    print match.inspect if match.name
    print " -- " if match.name
    puts match.name if match.name
    puts "  " + match.matches.inspect if match.name
    match.matches.each {|x| print_tree(x)}
  end
end

def list_tree(match, list)
  if match.matches.length == 0
    return
  else
    list << match if match.name
    match.matches.each {|x| list_tree(x, list)}
  end
end

def clean_tree(match, new_tree)
  if match.matches.length == 0
    return
  else
    if match.name
      sub_tree = []
      match.matches.each {|x| clean_tree(x,sub_tree)}
      new_tree << [match, sub_tree]
    else
    match.matches.each {|x| clean_tree(x,new_tree)}
    end
  end
end


def test_arithmetic
  list = []
  list_tree(Survenity.parse(File.open("tests/test_5.svy").read), list)
  list.each_index do
    |i|
    puts "#{i}. #{list[i].name}"
    puts list[i].to_s 
  end
  
  variable_hash = {}
  variable_hash[:x] = [1, 2, 3]
  variable_hash[:y] = 10
  variable_hash[:t] = 0
  
  include Tam
  #Tam::interpret_statement(list[54..57], variable_hash)
  Tam::interpret_statement(list[18..28], variable_hash)
  puts "======"
  puts variable_hash.inspect
end

def test_tam_interpreter
  
  match = Survenity.parse(File.open("tests/test_5.svy").read)
  statement_list = match.clean_blocks[0].captures[:statement]
  include Tam
  variable_hash = {}
  run_interpreter(statement_list, variable_hash)
  puts variable_hash.inspect
end


def test_compiler
  
  survey = parse_survey_file("tests/test_3.svy")
  
  include Kaywinnit
  compile_survey(survey)
  
end



Citrus.load 'Survenity'
test_compiler

#survey = parse_survey_file("tests/test_5.svy")


#print_tree(Survenity.parse(File.open("tests/test_5.svy").read))

#include Kaywinnit
#compile_survey(survey)

#match = Survenity.parse(File.open("tests/test_4.svy").read)
#match.clean_blocks.each {|x| puts x.name}
#puts "******"
#x = translate_experiment(match.clean_blocks[0])
#puts x.name.inspect
#puts x.question
#puts x.after_table_text
#puts x.alternatives.inspect
#puts x.variables.inspect
#puts ""
#puts x.exp_design.inspect
#puts x.attribute_labels.inspect
#puts x.option_representations.inspect
#puts q.name.inspect
#puts q.section
#puts match.class

#puts match.clean_blocks[0].constant.value.inspect

#puts new_tree.length
#puts new_tree[0].length
#puts new_tree.to_s
#new_tree[1][1][1][1][2][1].each do
#  |x|
#  #puts x.inspect
#  puts x.inspect + " -- " + x[0].name.to_s
#  puts
#  #puts x.inspect + " -- " + x.name.to_s
#end
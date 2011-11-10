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
load "#{File.dirname(__FILE__)}/survenity_nodes.rb"
load "#{File.dirname(__FILE__)}/mal_error_handler.rb"

class ParsedSurvey
  
  attr_accessor :pages, :experiments
  
end

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

# Parses a survey file and returns a ParsedSurvey object which just holds
# the page matches and experiment matches
def parse_survey_file(file_path)
  Citrus.load "#{File.dirname(__FILE__)}/Survenity"
  
  begin
    match = SurvenityGrammar.parse(File.open(file_path).read)
  rescue Errno::ENOENT
    raise "Parser could not find the survey file.  File at the path given, #{file_path}, not found."
  rescue Citrus::ParseError => error
    Mal::ErrorHandler.parse_with_treetop(file_path)
    puts "\n===============\n\nCitrus Error Output:"
    raise error
  end
  
  #Place matches into different categories depending on whether the block corresponds to a page/question or choice experiment
  cleaned_blocks = match.clean_blocks
  pages = []
  experiments = []
  cleaned_blocks.each do
    |block|
    if block.name == :choice_experiment
      experiments << block
    else
      pages << block
    end
  end
  
  survey = ParsedSurvey.new
  survey.pages = pages
  survey.experiments = experiments
  
  return survey
end
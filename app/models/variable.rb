class Variable < ActiveRecord::Base
  belongs_to :respondent
  serialize :variable_hash
end

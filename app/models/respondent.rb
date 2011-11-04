class Respondent < ActiveRecord::Base
  has_one :response
  has_one :variable
end

class Question < ActiveRecord::Base
  belongs_to :page
  serialize :question_object
end

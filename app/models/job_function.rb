class JobFunction < ActiveRecord::Base
  validates :name ,:presence => true ,:uniqueness => true
  
  
  def is_interesting?
    self.id < 3
  end
end

class JobFunction < ActiveRecord::Base
  validates :name ,:presence => true ,:uniqueness => true
   attr_accessible :name 
  
  def is_interesting?
    self.id < 3
  end
end

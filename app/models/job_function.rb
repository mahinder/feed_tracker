class JobFunction < ActiveRecord::Base
  validates_uniqueness_of :name
  validates_presence_of :name
  
  def is_interesting?
    self.id < 3
  end
end

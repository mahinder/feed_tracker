class Industry < ActiveRecord::Base
  validates :name , :uniqueness => true , :presence => true
   attr_accessible :name 
  def self.fill_it_up
    Industry.delete_all
    Industry.create :name=>"Banking & Financial Services"
    Industry.create :name=>"Commercial Real Estate"
    Industry.create :name=>"Education"
    Industry.create :name=>"Energy"
    Industry.create :name=>"Environment"
    Industry.create :name=>"Health Care"
    Industry.create :name=>"Human Resources"
    Industry.create :name=>"Insurance"
    Industry.create :name=>"Insurance - P&C - Commercial"
    Industry.create :name=>"Insurance - P&C - Personal"
    Industry.create :name=>"Insurance - Life"
    Industry.create :name=>"Insurance - Health"
    Industry.create :name=>"Legal Services"
    Industry.create :name=>"Logistics & Transportation"
    Industry.create :name=>"Manufacturing"
    Industry.create :name=>"Media & Marketing"
    Industry.create :name=>"Residential Real Estate"
    Industry.create :name=>"Retailing & Restaurants"
    Industry.create :name=>"Sports Business"
    Industry.create :name=>"Technology"
    Industry.create :name=>"Technology - Computer Software"
    Industry.create :name=>"Technology - Computer Hardware"
    Industry.create :name=>"Technology - Semiconductor"
    Industry.create :name=>"Technology - Bio-tech"
    Industry.create :name=>"Technology - Medical Devices"
    Industry.create :name=>"Technology - Professional Services"
    Industry.create :name=>"Technology - Green Tech"
    Industry.create :name=>"Technology - Nano Technology"
    Industry.create :name=>"Technology - Mobile"
    Industry.create :name=>"Private Equity/Venture Capital"
    Industry.create :name=>"Travel"
  end
end

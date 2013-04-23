class Domain < ActiveRecord::Base
  belongs_to :verified_company
  belongs_to :company
  attr_accessible :verified_company_id , :company_id
end

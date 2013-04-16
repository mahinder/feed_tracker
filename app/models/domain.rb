class Domain < ActiveRecord::Base
  belongs_to :verified_company
  belongs_to :company
end

# == Schema Information
#
# Table name: api_keys
#
#  id               :integer(4)      not null, primary key
#  access_token     :string(255)
#  user_id          :integer(4)
#  organisation_key :string(255)
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#

class ApiKey < ActiveRecord::Base
  belongs_to :user
  validates :access_token , :user_id , :organisation_key ,:presence => true , :uniqueness => true
  attr_accessible :user_id , :access_token, :organisation_key
end

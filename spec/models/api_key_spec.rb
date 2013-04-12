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

require 'spec_helper'

describe ApiKey do
  before(:each) do
    @attr = {
      :user_id => 1 ,
      :access_token=> "sasdfsdfsdfsdfsdfsdfsdfsd",
      :organisation_key =>"afdasdasdasdasdasda",
     }
  end
  it "should create a new instance given a valid attribute" do
    ApiKey.create!(@attr)
  end
  
  it "should be invalid without user id" do
    api_key = ApiKey.new(@attr.merge(:user_id => ""))
    api_key.should_not be_valid
  end
  
  it "should be invalid without access_token" do
    api_key = ApiKey.new(@attr.merge(:access_token => ""))
    api_key.should_not be_valid
  end
  it "should be invalid without organisation key" do
    api_key = ApiKey.new(@attr.merge(:organisation_key => ""))
    api_key.should_not be_valid
  end
  
  it "should be invalid with dublicate accessn token and organisation key" do
    ApiKey.create!(@attr)
    duplicate = ApiKey.new(@attr)
    duplicate.should_not be_valid
  end
  
  it "should responde to user" do
   apikey =  ApiKey.new(@attr)
   apikey.should respond_to(:user) 
  end
  
  
end

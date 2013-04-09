  # == Schema Information
#
# Table name: users
#
#  id                     :integer(4)      not null, primary key
#  user_name              :string(255)
#  created_at             :datetime        not null
#  updated_at             :datetime        not null
#  email                  :string(255)     default(""), not null
#  encrypted_password     :string(255)     default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer(4)      default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  authentication_token   :string(255)
require 'spec_helper'

describe User do
  before(:each) do
    @attr = {
      :user_name =>"organisation",
      :email=> "organisation@yahoo.com",
      :password =>"organisation",
      :password_confirmation => "organisation"
    }
  end
   after :each do 
     User.delete_all
   end
  def user_create
    User.create!(@attr)
  end
  it "should create a new instance given a valid attribute" do
    user_create
  end
  
  it "should be invalid without user name" do
    no_name_user = User.new(@attr.merge(:user_name => ""))
    no_name_user.should_not be_valid
  end
  
  it "should be invalid with dublicate user_name" do 
    user_create
    dublicate_user_name = User.new(@attr.merge(:user_name => "organisation"))
    dublicate_user_name.should_not be_valid
  end
  
  
  
end

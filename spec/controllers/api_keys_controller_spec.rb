require 'spec_helper'
require 'factory_girl_rails'
include Devise::TestHelpers
include Warden::Test::Helpers

describe ApiKeysController, :type => :controller  do
  before :each do
    user = FactoryGirl.create(:user)
    sign_in user
  end
  render_views  
  
  after :each do
    User.delete_all
  end    

  describe "GET 'index'" do
    it "should be successful" do
      get :index
      response.should be_success
    end
  end 
  
  describe "JSON POST 'create'" do
    describe "success" do
     
      it "should be successful for create" do
        post :create  , :format => :json
        response.should be_success
        parsed_body = JSON.parse(response.body)
        parsed_body['valid'].should be_true      
      end 
      
      it "should successfully add record" do
        lambda do
          post :create, :format => :json
        end.should change(ApiKey, :count).by(1)
      end
    end
  end
end


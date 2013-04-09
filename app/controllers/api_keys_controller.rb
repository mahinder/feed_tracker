class ApiKeysController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    
  end
  
  def create
    api_key =  ApiKey.new(:user_id => current_user.id)
    begin
      acctoken = api_key.access_token = SecureRandom.hex
      orgkey = api_key.organisation_key = SecureRandom.hex
    end while api_key.class.exists?(:access_token => acctoken , :organisation_key => orgkey)
    respond_to do |format|
      if api_key.save! 
        format.json { render json: {:valid => true , :access_token => acctoken , :organisation_key => orgkey , :api_id => api_key.id  } }
      else
        format.json { render json: {:valid => false , :notice => "Sorry some thing went wrong" } }  
      end   
    end
  end  
  
  def update
    api_key =  ApiKey.find(params[:id])
    begin
      acctoken = api_key.access_token = SecureRandom.hex
      orgkey = api_key.organisation_key = SecureRandom.hex
    end while api_key.class.exists?(:access_token => acctoken , :organisation_key => orgkey)
    respond_to do |format|
      if api_key.save! 
        format.json { render json: {:valid => true , :access_token => acctoken , :organisation_key => orgkey } }
      else
        format.json { render json: {:valid => false , :notice => "Sorry some thing went wrong" } }  
      end   
    end
 
  end   



  
end


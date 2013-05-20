class Mock::UserApisController < ApplicationController
  require "ruby-debug"
  respond_to :json
  def mock_user_response
      puts   params 
      render :json => {status: "200 ok" }
    end
  
  
end

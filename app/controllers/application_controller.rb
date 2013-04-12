class ApplicationController < ActionController::Base
  protect_from_forgery
  
   def protect_admin_access
    if user_signed_in?
      if !current_user.is_admin?
        redirect_to index_path
      end  
    else
      redirect_to :controller => '/api_keys', :action => 'index'
    end
  end   
end

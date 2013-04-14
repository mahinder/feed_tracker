class ApplicationController < ActionController::Base
  protect_from_forgery
    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_path, :flash => { :error => exception.message } 
    end
   def protect_admin_access
	
    if user_signed_in?
      if !current_user.is_admin?
        redirect_to root_url
      end  
    else
      redirect_to root_url
    end
  end   
end

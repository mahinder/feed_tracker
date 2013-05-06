module Api 
  class RssFeedsController < ApplicationController

    protect_from_forgery :except => :create_bulk_rss_feeds    
    skip_before_filter :authenticate_user!
    before_filter :restrict_access
    respond_to :json
    
    def create_bulk_rss_feeds 
      params[:feeds].each do |feed|
        begin
          NewsFeed.create!(:user_id => @user.id , :feed_url => feed) if feed =~ URI::regexp 
        rescue
          next
        end
      end   
      render :json => {status: "200 ok" }
    end 
    
    def retrive_information
      
      
      
    end
    
    
    

    private
    def restrict_access
      head :unauthorized unless ApiKey.exists?(access_token: request.env['HTTP_TOKEN'] , organisation_key: request.env['HTTP_ORGANISATION_KEY'])
      @user = ApiKey.find_by_organisation_key(request.env['HTTP_ORGANISATION_KEY'])
    end
  end
end
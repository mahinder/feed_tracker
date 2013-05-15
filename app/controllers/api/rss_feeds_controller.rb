module Api 
  class RssFeedsController < ApplicationController
    protect_from_forgery :except => :create_bulk_rss_feeds    
    skip_before_filter :authenticate_user!
    before_filter :restrict_access
    respond_to :json
    require 'ruby_debug'
    
    def create_bulk_rss_feeds 
      params[:feeds].each do |feed|
        begin
         feed_params =  Rack::Utils.parse_query URI(feed).query
         newsfeed = NewsFeed.new(:user_id => @user.id , :feed_url => feed , :tagged_for => feed_params['tags'].split(','),:scope =>  feed_params['scope']) if feed =~ URI::regexp 
         newsfeed.save!
        rescue
          next
        end
      end   
      render :json => {status: "200 ok" }
    end 
    
    def mock_user_response
      p params
    end
    
    
    

    private
    def restrict_access
      head :unauthorized unless ApiKey.exists?(access_token: request.env['HTTP_TOKEN'] , organisation_key: request.env['HTTP_ORGANISATION_KEY'])
      @user = ApiKey.find_by_organisation_key(request.env['HTTP_ORGANISATION_KEY'])
    end
  end
end
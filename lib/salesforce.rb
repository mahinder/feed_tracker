module Salesforce
  def sf_oauth_client(include_auth_code = false, options = {})
    client = OAuth2::Client.new(AppConfig['salesforce_key'], AppConfig['salesforce_secret'],
                                {
                                    :site => AppConfig['salesforce_site'],
                                    :token_url => '/services/oauth2/token',
                                    :token_method => :post,
                                    :authorize_path => '/services/oauth2/authorize',
                                    :authorize_url => AppConfig['salesforce_authorize_url'],
                                    :response_type => 'code',
                                    :display => 'touch',
                                    :immediate => true
                                }.merge(options))

    include_auth_code ? get_sf_auth_code(client) : client
  end

  def get_sf_auth_code(client)
    client.auth_code.authorize_url(:redirect_uri => "http://#{AppConfig['base_url']}/auth/salesforce/callback")
  end

  def client_from_oauth_token(token, debug = false)
    client = nil

    if token
      access_token = token.token
      instance_url = token.params["instance_url"]
      m = token["id"].match(/\/id\/([^\/]+)\/([^\/]+)$/)

      client = Databasedotcom::Client.new
      client.authenticate(:token => access_token, :instance_url => instance_url)

      client.org_id = m[1] rescue nil
      client.user_id = m[2] rescue nil
      client.instance_url = instance_url
      client.host = parse_domain(client.instance_url)
      client.oauth_token = access_token
      client.refresh_token = token.refresh_token
      client.debugging = debug
    end

    $env[:sf_client] = client
    $env[:sf_client]
  end

  def get_authorized_sf_client(auth_code)
    oauth_client = sf_oauth_client
    query_hash = {:code => auth_code, :grant_type => 'authorization_code', :redirect_uri => "https://#{AppConfig['base_url']}/auth/salesforce/callback"}

    access_token = oauth_client.auth_code.get_token(auth_code, query_hash)
    client_from_oauth_token(access_token, Rails.env.development?)
  end

  def client_with_refreshed_token(refresh_token)
    client = sf_oauth_client
    response = OAuth2::AccessToken.from_hash(client, :refresh_token => refresh_token).refresh!

    if response.token
      client_from_oauth_token(response)
    else
      nil
    end
  end

  def parse_domain(url = nil)
    url = url.to_s if url.is_a?(Symbol)
    unless url.nil?
      url = "https://" + url if (url =~ /http[s]?:\/\//).nil?
      begin
        url = Addressable::URI.parse(url)
      rescue Addressable::URI::InvalidURIError
        url = nil
      end
      url = url.host unless url.nil?
      url.strip! unless url.nil?
    end
    url = nil if url && url.strip.empty?
    url
  end

  def sf_client(user)
    client = $env[:sf_client]

    if client
      client
    elsif user.sf_auth
      client_with_refreshed_token(user.sf_auth.refresh_token)
    end
  end

  def generate_sf_link(user, state = '/')
    sf_client(user) ? "popReminder($(this))" : "window.location.href='#{sf_oauth_client(true, {:state => state})}'"
  end

  def create_sf_lead(client, attr_hash)
    begin
      client.materialize("Lead")

      new_lead = Lead.new(attr_hash)
      new_lead.save
    rescue Exception => e
      AdminAlert.create(:message => {:message => e.message, :trace => e.backtrace})
      nil
    end
  end

  def update_sf_lead(client, attr_hash, lead_id)
    begin
      client.materialize("Lead")

      lead = Lead.find(lead_id) rescue nil
      lead ? lead.update_attributes(attr_hash) : true
    rescue Exception => e
      AdminAlert.create(:message => {:message => e.message, :trace => e.backtrace})
      nil
    end
  end

  def destroy_sf_lead(client, lead_id)
    begin
      client.materialize("Lead")

      lead = Lead.find(lead_id) rescue nil
      lead ? lead.delete : true
    rescue Exception => e
      AdminAlert.create(:message => {:message => e.message, :trace => e.backtrace})
      nil
    end
  end

end

module Databasedotcom
  class Client
    attr_accessor :org_id
    attr_accessor :user_id
    attr_accessor :endpoint
  end
end
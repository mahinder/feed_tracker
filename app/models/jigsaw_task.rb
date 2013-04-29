require 'jigsaw'
require 'open-uri'
require 'rexml/document'
require 'domainatrix'

class JigsawTask < ActiveRecord::Base
  
  attr_accessor :url_filter
  
  def async_do_batch_enrichment()
    Resque.enqueue(JigsawAppend)
  end  
  
  def batch_enrichment status
    initialize_url_filters
    candidate_companies = Company.find(:all, :select => "id, name, url,last_enriched_at, display_name", :order => "id DESC",:conditions => ["jigsaw_flagged = ? and ( last_enriched_at < ?  or last_enriched_at is null )", false, 30.days.ago])
    total = candidate_companies.count
    counter = 0
    candidate_companies.each do |company|
      counter += 1
      status.at(counter,total,"At #{counter} of #{total}")
      JigsawTask.enrich(company)
    end
    self.update_attribute(:last_completed, Time.now())
  end
  
  def self.enrich company
#    jc = Jigsaw::JCompany.new('x82z8mfmr6hbkn7k9tkrkz26')
#    company_website = company.url
#    if company_website == nil or company_website.blank?
#      # Try to fetch the company website.
#      company_website = JigsawTask.fetch_company_url company
#      if company_website != nil and !company_website.strip.blank?
#        company.url = company_website
#        company.save
#      end
#    end
#    
#    if !company_website.strip.blank?
#      jc.append_company_by_id(company.id)
#    end
#    company.last_enriched_at = Time.now();
#    company.save
  end
  
  private
  # Fetches company url for given company name.
  def self.fetch_company_url( company )
    begin
      # Try to fetch it from our database first.
      # If not already in database then try to find it on the web.
      sql_friendly_name = make_sql_friendly( company.name )
      similar_company = Company.find :first, :select =>"id,name,url", :conditions => ["id <> ? and name like ? and url is not null", company.id, sql_friendly_name]
      if similar_company != nil and similar_company.url != nil and !similar_company.url.blank?
        return similar_company.url
      else
        return get_company_url_from_internet( company.name )
      end
    rescue
      return ''
    end
  end
  
  # Searches the internet for url by given company name and returns it.
  def get_company_url_from_internet( name )
    url_friendly_name = make_url_friendly name
    api_url = "http://api.bing.net/xml.aspx?AppId=65E209AA925DE92F7B6235CFD453A33BE4893A66&Version=2.2&Market=en-US&Query=#{url_friendly_name}&Sources=web+spell&Web.Count=1"
    url = ''
    response = open(api_url)
    xml = response.read
    doc = REXML::Document.new xml
    if ( doc != nil )
      results = doc.elements.to_a("//web:WebResult/web:Url")
      url = results[0]
    else
      url = "nothing"
    end
    if url != nil
      begin
        domain_name = Domainatrix.parse(url.text)
        url = "#{domain_name.domain}.#{domain_name.public_suffix}"
        if is_noise? name, url
          url = ''
        end
      rescue
        url = ''
      end
    else
      url = ''
    end
    return url
  end
  
  # Makes the string safe for SQL. It replaces single quotes with two single quotes.
  def make_sql_friendly( name )
    return name.strip.gsub( "'", "''" )
  end
  
  # Removes characters which might mess up the url.
  def make_url_friendly( name )
    return name.strip.gsub(/[^A-Za-z0-9_]/, '+')
  end
  
  # Url filters for getting rid of some common noise encountered while finding urls.
  def initialize_url_filters
    # We use a hash which tells the domains to filter.
    # The hash value tells that if company name contains that string then don't filter
    @url_filter = Hash.new
    @url_filter["facebook.com"] = "facebook"
    @url_filter["linkedin.com"] = "linkedin"
    @url_filter["wikipedia.org"] = "wikipedia"
    @url_filter["yahoo.com"] = "yahoo"
    @url_filter["zdnet.com"] = "zdnet"
    @url_filter["yelp.com"] = "yelp"
    @url_filter["yellowpages.com"] = "yellowpages"
    @url_filter["thefreelibrary.com"] = "thefreelibrary"
    @url_filter["thefreedictionary.com"] = "thefreedictionary"
    @url_filter["superpages.com"] = "superpages"
    @url_filter["businessweek.com"] = "week"
    @url_filter["indiamart.com"] = "mart"
    @url_filter["naukri.com"] = "naukri"
    @url_filter["monsterindia.com"] = "monster"
    @url_filter["answers.com"] = "answers"
    @url_filter["sulekha.com"] = "sulekha"
    @url_filter["asklaila.com"] = "asklaila"
    @url_filter["blogspot.com"] = "blogspot"
    @url_filter["manta.com"] = "manta"
    @url_filter["zoominfo.com"] = "zoom"
    @url_filter["twitter.com"] = "twitter"
    @url_filter["hotfrog.com"] = "hotfrog"
    @url_filter["amazon.com"] = "amazon"
  end
  
  # Checks against common websites to avoid wrong urls.
  def is_noise?( name, url )
    name_key = @url_filter[url.downcase]
    if ( name_key != nil )
      if name.downcase.include? name_key
        return false
      else
        return true
      end
    else
      return false
    end
  end
end

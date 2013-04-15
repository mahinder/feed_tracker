require 'rubygems'
require 'calais'

class FeedEnrichment 
  
  def feed_enrichment
    @calais_key = 'jwua5bvnh7w2m3ks3uzsy9gy'
    news_list ||= FeedEntry.pending_enrichment || []
    news_list.each do |news|
     begin
      response_raw = Calais.enlighten(:content => "#{news.headline}\n#{news.description}",:content_type => :html,:license_id => @calais_key )
      news.calais_data = response_raw
      response = Calais::Response.new response_raw
      response.entities.each do |entity|
        case entity.type
        when 'Company'
          company_name = entity.attributes['name']
          CompaniesInNews.create_company_tag(news.id, company_name) if company_name.split(' ').count < 5 #The number of words is a company is not a standard. It is based on a hunch.
        when 'Person'
          person_name = HumanName.new entity.attributes['name']
          PeopleInNews.tag_person_in_news(news, person_name.first_name, person_name.last_name, nil, nil)
        when 'IndustryTerm'
          industry_name = entity.attributes['name']
          IndustriesInNews.create_industry_tag news.id, industry_name
        end
      end
      news.is_enriched = true
      news.save
      #Open calais allows only 4 transactions per second. So, we'll put a worst case delay.
      sleep(1.0/4.0)
     rescue
       next
     end
    end if news_list
  end
    
end
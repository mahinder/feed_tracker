require 'rubygems'
require 'calais'
class FeedEnrichment 
  def self.feed_enrichment
    @calais_key = 'jwua5bvnh7w2m3ks3uzsy9gy'
    news_list ||= News.pending_enrichment || []
    news_list.each do |news|      
      if news.news_feed.scope == "InCompanies"
        begin
         tagging_in_company news
         is_enriched news 
        rescue
          next
        end 
      end  
      
      if news.news_feed.scope == "ByCompanies"
         tagging_by_company news
         is_enriched news 
      end
      
      if news.news_feed.scope == "All"
         tagging_by_company news 
         tagging_in_company news
         is_enriched news 
      end
      
   end if news_list
  end
  
 def  self.tagging_by_company news
   tagged_for = news.news_feed.tagged_for
   tagged_for.each do |tag|
      CompaniesInNews.create_company_tag(news.id, tag) if tag.split(' ').count < 5
   end
   is_enriched news
 end
 
 def  self.tagging_in_company news
          response_raw = Calais.enlighten(:content => "#{news.headline}\n#{Sanitize.clean(news.description)}",:content_type => :html,:license_id => @calais_key )
          news.calais_data = response_raw
          response = Calais::Response.new response_raw
          response.entities.each do |entity|
            begin 
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
            rescue
              next
            end    
          end
            
          sleep(1.0/4.0)
          #Open calais allows only 4 transactions per second. So, we'll put a worst case delay.
        
 end
 
 def self.is_enriched news
   news.is_enriched = true
   news.save!
 end
  
  
end



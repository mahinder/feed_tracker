class CompaniesInNews < ActiveRecord::Base
  attr_accessible   :company_id, :news_id ,:relevance
  cattr_accessor :skip_callbacks
  validates :company_id, :uniqueness => {:scope => :news_id}
  belongs_to :news
  belongs_to :company
  
  after_save lambda { :add_additional_tags_to_news }, :unless => :skip_callbacks
  
  def add_additional_tags_to_news
    company = Company.find(self.company_id, :select => "id,url,name,domain_id,industry,industry2,industry3,country")
    JigsawTask.enrich(company) rescue ''

    industry1 = company.industry
    industry2 = company.industry2
    industry3 = company.industry3
    IndustriesInNews.create_industry_tag(self.news_id, industry1)
    IndustriesInNews.create_industry_tag(self.news_id, industry2) unless industry1 == industry2
    IndustriesInNews.create_industry_tag(self.news_id, industry3) unless industry3 == industry1 or industry3 == industry2

    # Tag location
    location_name = company.country
    Location.tag_in_news(self.news_id, location_name) if location_name
  end
  
  def self.create_company_tag(news_id, name, relevance = 0)
    company = Company.find_unique name
    return nil if company.nil?
    found_cin = CompaniesInNews.find_by_news_id_and_company_id news_id, company.id
    if found_cin.nil?
      CompaniesInNews.create :company_id => company.id, :news_id => news_id, :relevance => (relevance * 100).to_i
      return company
    else
      return nil
    end
  end
end

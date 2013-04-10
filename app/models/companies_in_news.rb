class CompaniesInNews < ActiveRecord::Base
  attr_accessible   :company_id, :feed_entry_id
  validates :company_id, :uniqueness => {:scope => :feed_entry_id}
  belongs_to :feed_entry
  belongs_to :company
   
  def self.create_company_tag news_id, name
    company = Company.find_unique name
    return nil if company.nil?
    found_cin = CompaniesInNews.find_by_feed_entry_id_and_company_id news_id, company.id
    if found_cin.nil?
      CompaniesInNews.create :company_id=>company.id, :feed_entry_id => news_id
      return company
    else
      return nil
    end
  end
end

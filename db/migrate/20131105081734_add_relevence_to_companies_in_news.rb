class AddRelevenceToCompaniesInNews < ActiveRecord::Migration
  def self.up
    add_column :companies_in_news, :relevance, :integer, :default => 0

    CompaniesInNews.update_all "relevance = 100"

    # Update previous 1 month news
    all_news = News.find(:all, :conditions => ['calais_data IS NOT NULL and published_at > ?', 1.month.ago])

    all_news.each do |news|
      data = ''
      calais_data = Calais::Response.new news.calais_data rescue nil
      if calais_data
        calais_data.entities.each { |entity| data = entity if entity.type == 'Company' }

        unless data.blank?
          company = Company.find_by_name(data.attributes['name'])
          if company
            company_in_news = CompaniesInNews.find_by_company_id_and_news_id(company.id, news.id)
            if company_in_news
              company_in_news.update_attributes(:relevance => (data.relevance.to_f * 100).to_i, :skip_callbacks => true)
              puts "Updated CompaniesInNews record with ID: #{company_in_news.id}"
            end
          end
        end
      end
    end
  end

  def self.down
    remove_column :companies_in_news, :relevance
  end
end

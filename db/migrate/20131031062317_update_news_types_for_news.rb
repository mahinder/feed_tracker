class UpdateNewsTypesForNews < ActiveRecord::Migration
  def self.up
    new_news_type_ids = []
    
    news_types = ["Awards", "Bankruptcy", "Earnings Release", "Funding", "Financial", "Acquisition", "Product", "Joined Board", "New Company", "Re-Organization", "Layoffs"]
    
    news_types.each do |news_type|
      new_news_type_ids << NewsType.where(:name => news_type).create(:name => news_type).id
    end

    news_type_map = {
        'Acquisition' => 'Acquisition',
        'Job change' => 'Executive Activity',
        'Joined management' => 'Executive Activity',
        'Joined management as VP Marketing' => 'Executive Activity',
        'Recently funded' => 'Funding'
    }

    news_type_map.each_pair do |key, value|
      old_news_type = NewsType.find_by_name(key)
      news_type = NewsType.find_by_name(value)

      if old_news_type
        News.update_all("news_type_id = #{news_type.id}", "news_type_id = #{old_news_type.id}")
        #InterestingNewsType.update_all("news_type_id = #{news_type.id}", "news_type_id = #{old_news_type.id}")
       # NewsFeed.update_all("news_type_id = #{news_type.id}", "news_type_id = #{old_news_type.id}")
      end
    end

    NewsType.delete_all(['id NOT IN (?)', new_news_type_ids])
  end

  def self.down
  end
end

class UpdateNewsTypesForNews < ActiveRecord::Migration
  def self.up
    new_news_types = []
    new_news_types << (NewsType.find_or_create_by_name :name => "Awards")
    new_news_types << (NewsType.find_or_create_by_name :name => "Bankruptcy")
    new_news_types << (NewsType.find_or_create_by_name :name => "Earnings Release")
    new_news_types << (NewsType.find_or_create_by_name :name => "Executive Activity")
    new_news_types << (NewsType.find_or_create_by_name :name => "Funding")
    new_news_types << (NewsType.find_or_create_by_name :name => "Financial")
    new_news_types << (NewsType.find_or_create_by_name :name => "Acquisition")
    new_news_types << (NewsType.find_or_create_by_name :name => "Product")
    new_news_types << (NewsType.find_or_create_by_name :name => "Joined Board")
    new_news_types << (NewsType.find_or_create_by_name :name => "New Company")
    new_news_types << (NewsType.find_or_create_by_name :name => "Re-Organization")
    new_news_types << (NewsType.find_or_create_by_name :name => "Layoffs")

    news_type_map = {
        'Acquisition' => 'Acquisition',
        'Job change' => 'Executive Activity',
        'Joined management' => 'Executive Activity',
        'Joined management as VP Marketing' => 'Executive Activity',
        'Recently funded' => 'Funding'
    }

    news_type_map.each_pair do |key, value|
      old_news_type = NewsType.find_by_name(key)
      news_type = NewsType.find_by_name value

      if old_news_type
        News.update_all("news_type_id = #{news_type.id}", "news_type_id = #{old_news_type.id}")
        #InterestingNewsType.update_all("news_type_id = #{news_type.id}", "news_type_id = #{old_news_type.id}")
       # NewsFeed.update_all("news_type_id = #{news_type.id}", "news_type_id = #{old_news_type.id}")
      end
    end

    new_news_type_ids = new_news_types.collect(&:id)
    NewsType.delete_all(['id NOT IN (?)', new_news_type_ids])
  end

  def self.down
  end
end

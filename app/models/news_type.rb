class NewsType < ActiveRecord::Base
  validates :name ,:presence => true ,:uniqueness => true
attr_accessible :name
  def news(user, from_date, args={})
    condition = SmartTuple.new(" AND ")
    condition << ["interesting_news.user_id = ? AND ready = 1
                         AND published_at > ?", user.id, from_date]
    condition << ["news.headline like ?", "%#{args[:search]}%"] if args[:search]

    News.all(
        :select => "news.id, news.headline,news.reason, news.url, news.news_type_id, news.origin_domain, updated_at, published_at",
        :order => "DATE(news.published_at) desc",
        :joins => "INNER JOIN interesting_news on interesting_news.news_id = news.id
                   INNER JOIN `companies_in_news` ON `companies_in_news`.news_id = `news`.id",
        :conditions => condition.compile
    )
  end

  def self.news_type_data(date)
    NewsType.find_by_sql(
      "SELECT nt.name name, COUNT(DISTINCT n.id) news_count, COUNT(DISTINCT cin.company_id) companies_count, COUNT(DISTINCT ints.user_id) interested_users_count
        FROM news_types nt
          LEFT OUTER JOIN news n ON n.news_type_id = nt.id
          LEFT OUTER JOIN companies_in_news cin ON n.id = cin.news_id
          LEFT OUTER JOIN interesting_news_types ints ON ints.news_type_id = nt.id
          LEFT OUTER JOIN users u ON u.id = ints.user_id
        WHERE DATE(n.published_at)='#{date}' and u.unsubscribed_at IS NULL and u.news_email_frequency=1
        GROUP BY nt.id"
    )
  end
end

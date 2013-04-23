require 'set'

class InterestingNews < ActiveRecord::Base
  belongs_to :news
  validates :news_id, :user_id , :presence => true
  validates :news_id, :uniqueness => {:scope => :user_id}

  def self.refresh_for_user task, user_id
    user = User.find user_id
    InterestingNews.cleanup_interesting_news task, user
    int_news_ids = user.interesting_news.collect { |item| item.news_id }
    if int_news_ids.empty?
      news = News.find :all, :conditions => ["news.updated_at > DATE(?) and ready=1 and blocked=0", 1.month.ago]
    else
      news = News.find :all, :conditions => ["news.updated_at > DATE(?) and ready=1 and blocked=0 and id not in (?)", 1.month.ago, int_news_ids]
    end

    News.bulk_process(task, [user], news)
    task.completed unless task.nil?
  end

  def self.cleanup_interesting_news task, user_id
    user = User.find user_id
    interesting_news = user.interesting_news
    total=interesting_news.count
    progress=0
    interesting_news.each do |item|
      progress += 1
      task.at(progress, total, "Interesting news cleanup:At #{progress} of #{total} news items") unless task.nil?
      item.remove_if_not_interesting(user)
    end
    task.completed unless task.nil?
  end

  def remove_if_not_interesting user
    news = self.news
    unless (news.updated_at > 1.month.ago and news.interesting?(user) and (news.has_any_linkedin_connections?(user) or news.has_any_psn_connections?(user) or news.has_any_target_companies?(user)))
      puts "Destroyed #{self.id}"
      self.destroy
    end
  end

  def self.on_news_update task, news_id
    news = News.find news_id
    if !news.ready || news.blocked
      InterestingNews.delete_all "news_id = #{news_id}"
    else
      users = User.find(:all, :order => "last_login_at desc")
      users.each do |user|
        news.remove_if_not_interesting(user)
      end
      News.bulk_process(task, users, [news])
    end
    task.completed unless task.nil?
  end

  def self.bulk_process_on_news_creation(reason)
    news_ids = Set.new
    conditions = "n.processed = 0 AND u.id IS NOT NULL"

    # priority 4 means unprocessed interesting news record that is interesting by newstype
    priority = (reason == 'TargetCompany' ? 3 : 4)

    to_be_interested_by_target_companies = InterestingNews.find_by_sql("
            SELECT n.id news_id, u.id user_id
            FROM news n
              LEFT OUTER JOIN companies_in_news cin ON cin.news_id = n.id
              LEFT OUTER JOIN target_companies tc ON tc.company_id = cin.company_id
              LEFT OUTER JOIN users u ON u.id = tc.user_id
            WHERE #{conditions}
      ")

    to_be_interested_by_news_types = InterestingNews.find_by_sql("
            SELECT n.id news_id, u.id user_id
            FROM news n
              LEFT OUTER JOIN news_types nt ON nt.id = n.news_type_id
              LEFT OUTER JOIN interesting_news_types int_nt ON int_nt.news_type_id = n.news_type_id
              LEFT OUTER JOIN users u ON u.id = int_nt.user_id
            WHERE #{conditions}
      ")

    to_be_interested_by_target_companies.each do |int_by_tc|
      news_ids.add(int_by_tc.news_id)
      InterestingNews.create(:user_id => int_by_tc.user_id, :news_id => int_by_tc.news_id, :priority => priority, :reason => reason)
    end

    to_be_interested_by_news_types.each do |int_by_nt|
      news_ids.add(int_by_nt.news_id)
      InterestingNews.create(:user_id => int_by_nt.user_id, :news_id => int_by_nt.news_id, :priority => priority, :reason => reason)
    end

    News.update_all("processed = 1", ["id IN (?)", news_ids])
    PrioritizeInterestingNews.create({'reason' => Constants::CONNECTIONS_TYPE_IN_NEWS::PSN_LINKEDIN}) unless reason == 'TargetCompany'
  end

  def self.prioritize_interesting_news(task = nil)
    interesting_news = InterestingNews.find_all_by_reason_and_priority('NewsType', 4)
    interesting_news_grouped_by_user_id = interesting_news.group_by(&:user_id)

    progress = 0
    priority = 1000
    total = interesting_news_grouped_by_user_id.count

    interesting_news_grouped_by_user_id.each_pair do |user_id, interesting_news|
      progress += 1
      news_ids = interesting_news.collect(&:news_id)
      news_items = News.find(:all, :conditions => ['id IN (?)', news_ids])
      user = User.find(user_id)

      map = News.generate_companies_news_map(user, news_items, false)
      li_access_token = user.generate_linkedin_access_token
      map_total = map.count
      map_progress = 0
      map.each do |company, news_items|
        map_progress += 1
        if task
          if total == 1
            task.at(map_progress, map_total, "Processed #{map_progress} out of #{map_total} companies")
          else
            task.at(progress, total, "At #{progress} of #{total} users| #{map_progress} out of #{map_total} companies")
          end
        end
        has_psn_connections = user.has_connections_in_company?(company)
        has_li_connections = li_access_token.nil? ? false : user.has_li_connections_in_company?(company, li_access_token)

        valid_candidate = true
        if has_psn_connections
          priority = 1
        elsif has_li_connections
          priority = 2
        else
          valid_candidate = false
        end

        if valid_candidate
          news_items.each do |news_item|
            interesting_news = InterestingNews.find_by_user_id_and_news_id(user.id, news_item.id)
            interesting_news.update_attributes(:has_psn_connections => has_psn_connections, :priority => priority)
          end
        end
      end
    end
    InterestingNews.update_all('priority=1000', :priority => 4)
  end
end

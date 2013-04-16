class News < ActiveRecord::Base
  attr_accessible :user_id, :news_type_id ,:description, :headline, :published_at, :url , :is_enriched ,:news_feed_id, :calais_data
  belongs_to :news_feeds
  has_many :people_in_news, :dependent => :destroy, :class_name => 'PeopleInNews'
  has_many :companies_in_news, :dependent => :destroy, :class_name => 'CompaniesInNews'
  has_many :companies, :through => :companies_in_news
  has_many :people, :through => :people_in_news
  validates :headline , :presence => true 
  has_many :industries_in_news, :dependent => :destroy, :class_name => 'IndustriesInNews'
  has_many :industries, :through => :industries_in_news
  has_many :locations_in_news, :dependent => :destroy, :class_name => 'LocationsInNews'
  has_many :locations, :through => :locations_in_news
  has_many :job_titles_in_news, :dependent => :destroy, :class_name => 'JobTitlesInNews'
  has_many :job_titles, :through => :job_titles_in_news
  has_many :job_functions_in_news, :dependent => :destroy, :class_name => 'JobFunctionsInNews'
  has_many :job_functions, :through => :job_functions_in_news
  has_many :interesting_news, :dependent => :destroy, :class_name => "InterestingNews"
  belongs_to :news_type
  belongs_to :user
  scope :pending_enrichment, :conditions => {:is_enriched => false}

  def clear_tags
    self.industries_in_news.delete_all
    self.locations_in_news.delete_all
    self.job_titles_in_news.delete_all
    self.job_functions_in_news.delete_all
  end

  def industries_in_news_ids=(ids)
    ids.each do |id|
      self.industries_in_news.create :industry_id => id
    end
  end

  def locations_in_news_ids=(ids)
    ids.each do |id|
      self.locations_in_news.create :location_id => id
    end
  end

  def companies_in_news_ids=(ids)
    ids.each do |id|
      self.companies_in_news.create :company_id => id
    end
  end

  def job_titles_in_news_ids=(ids)
    ids.each do |id|
      self.job_titles_in_news.create :job_title_id => id
    end
  end

  def job_functions_in_news_ids=(ids)
    ids.each do |id|
      self.job_functions_in_news.create :job_function_id => id
    end
  end

  def create_uid
    self.uid = Digest::SHA1.hexdigest "#{self.headline}" unless self.uid
  end

  def self.reasons
    NewsType.all.collect { |nr| nr.name }
  end

  def news_source_attributes=(news_source_attributes)
    name = news_source_attributes[:name].strip
    if name.blank?
      self.news_source_id = nil if self.news_source_id
    else
      source = NewsSource.find_or_create_by_name name
      self.news_source_id = source.id
    end
  end

  def news_headline
    self.news_type_id.nil? ? self.headline : "#{self.news_type.name.titlecase}: #{self.headline.squish}"
  end

  def news_headline_without_type
    self.news_type_id.nil? ? self.headline : "#{self.headline.squish}"
  end

  def news_type
    if news_type_id
      NewsType.find(news_type_id)
    else
      NewsType.new :name => 'Misc.'
    end
  end

  def connections_with_all_people user
    ppl_in_news = self.people
    return nil if ppl_in_news.nil?

    ppl_in_news.each do |person|
      self.connections_with_person(user, person)
    end

    return @connections_with_person
  end

  def connections_in_all_companies user
    comp_in_news = self.companies
    return nil if comp_in_news.nil?
    comp_in_news.each do |company|
      self.connections_in_company(user, company)
    end
    return @connections_in_company
  end

  def has_linkedin_connections_in_any_company? user
    access_token = user.generate_linkedin_access_token
    return false if access_token.nil?
    comp_in_news = self.companies
    return false if comp_in_news.nil?
    comp_in_news.each do |company|
      begin
        return user.has_li_connections_in_company? company, access_token
      rescue Exception => e
        if e.message == "#{Constants::ERRORS::LINKEDIN_THROTTLE_LIMIT}"
          break
        end
      end
    end
    return false
  end

  def has_linkedin_connections_with_any_person? user
    access_token = user.generate_linkedin_access_token
    return false if access_token.nil?
    ppl_in_news = self.people
    return false if ppl_in_news.nil?
    ppl_in_news.each do |person|
      result = PersonConnectionsCount.connections_count(Constants::CONNECTIONS_COUNT_SOURCE::LINKEDIN, user, person, :access_token => access_token)
      unless result[:error]
        count = result[:count]
        return true unless count.nil? or count == "0"
      else
        break if result[:error] == Constants::ERRORS::LINKEDIN_THROTTLE_LIMIT
      end
    end
    return false
  end

  def connections_with_person user, person
    @connections_with_person ||= {}
    @connections_with_person[person.id] ||= user.find_person_in_psn person
  end

  def connections_in_company(user, company)
    @connections_in_company ||= {}
    @connections_in_company[company.id] ||= user.find_connections_by_company company
  end

  def has_any_psn_connections?(user)
    connections_in_companies = self.connections_in_all_companies(user)
    connections_in_companies.each do |key, value|
      if value.empty? == false
        return true
      end
    end unless connections_in_companies.nil?
    return false
  end

  def has_any_linkedin_connections? user
    return true if self.has_linkedin_connections_in_any_company? user
  end

  def self.get_news_summary(news_by_target_interests, user, number_of_days)
    require 'set'
    summary = {}
    news_items_unique = Set.new

    news_by_target_interests.each do |news_type, news_items|
      news_items.each do |news_item|
        if !news_item.nil? || !news_items_unique.include?(news_item.id)
          news_type = news_item[:news_item].news_type
          type = news_type.name
          count = summary[type]
          if count
            summary[type] = count + 1
          else
            summary[type] = 1
          end
          news_items_unique.add news_item[:news_item].id
        end
      end
    end
    summary[:total] = news_items_unique.count
    return summary
  end

  def self.generate_companies_news_map user, news_items, sort_by_psn_connections = true
    companies_news_map = {}
    news_items.each do |news|
      is_news_interesting = news.interesting? user
      news_companies = news.companies
      news_companies.each do |company|
        if is_news_interesting or user.is_company_targeted?(company.id)
          if companies_news_map.key? company
            companies_news_map[company] << news
          else
            companies_news_map[company] = [news]
          end
        end
      end
    end
    companies_news_map = News.sort_companies_news_map companies_news_map, user if sort_by_psn_connections
    return companies_news_map
  end

  def self.sort_companies_news_map(companies_news_map, user)
    companies_news_map = companies_news_map.sort do |a, b|
      first = user.has_connections_in_company?(a[0]) ? 1 : 0
      second = user.has_connections_in_company?(b[0]) ? 1 : 0
      result = second <=> first
      if result == 0 #Both news have psn connections
        b[1].first.published_at <=> a[1].first.published_at
      else
        result
      end
    end
    return companies_news_map
  end

  def interesting?(user)
    #It was decided that a user would have to have at-least one filter to make a news interesting by filters.
    return false unless user.has_defined_news_interest_filters?

    #Now check if the news matches filters
    if (self.interesting_by_news_type?(user) and
          self.interesting_by_industries?(user) and
          self.interesting_by_locations?(user))
      return true
    else
      return false
    end
  end


  def interesting_by_industries? user
    user_interests = user.interesting_industries.collect { |t| t.industry_id }
    return true if user_interests.empty?
    news_tags = self.industries_in_news.collect { |t| t.industry_id }
    return false if news_tags.empty? #User has some preferences but no tags were set on the news    
    news_tags.each do |tag|
      return true if user_interests.include? tag
    end
    return false
  end

  def interesting_by_locations? user
    user_interests = user.interesting_locations.collect { |t| t.location_id }
    return true if user_interests.empty?
    news_tags = self.locations_in_news.collect { |t| t.location_id }
    return false if news_tags.empty? #User has some preferences but no tags were set on the news

    news_tags.each do |tag|
      return true if user_interests.include? tag
    end
    return false
  end

  def interesting_by_job_titles? user
    user_interests = user.interesting_job_titles.collect { |t| t.job_title_id }
    return true if user_interests.empty?
    news_tags = self.job_titles_in_news.collect { |t| t.job_title_id }
    return false if news_tags.empty? #User has some preferences but no tags were set on the news
    news_tags.each do |tag|
      return true if user_interests.include? tag
    end
    return false
  end

  def interesting_by_job_functions? user
    user_interests = user.interesting_job_functions.collect { |t| t.job_function_id }
    return true if user_interests.empty?
    news_tags = self.job_functions_in_news.collect { |t| t.job_function_id }
    return false if news_tags.empty? #User has some preferences but no tags were set on the news
    news_tags.each do |tag|
      return true if user_interests.include? tag
    end
    return false
  end

  def interesting_by_news_type? user
    interests = user.interesting_news_types.collect { |t| t.news_type_id }
    return (interests.empty? or interests.include?(self.news_type_id))
  end

  def remove_if_not_interesting user
    int_news = user.interesting_news.find_by_news_id self.id
    int_news.remove_if_not_interesting(user) unless int_news.nil?
  end

  def self.bulk_process task, users, news_items
    total = users.count
    progress = 0
    users.each do |user|
      progress += 1
      map = News.generate_companies_news_map user, news_items, false
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
        is_company_targeted = user.is_company_targeted?(company.id)
        valid_candidate = true
        if has_psn_connections
          has_psn_connections = true
          priority = 1
        elsif has_li_connections
          has_psn_connections = false
          priority = 2
        elsif is_company_targeted
          priority = 3
        else
          valid_candidate = false
        end

        if valid_candidate
          news_items.each do |news_item|
            if news_item.interesting? user or is_company_targeted
              user.interesting_news.create :news_id => news_item.id, :priority => priority
            end
          end
        end
      end
    end
  end

  def has_any_target_companies? user
    companies = self.companies.find :all, :select => "companies.id as id"
    found_interested_by_company= false
    companies.each do |company|
      found_interested_by_company = user.is_company_targeted?(company.id)
      break if found_interested_by_company
    end
    found_interested_by_company
  end

  def on_news_update
    job_id = NewsInterestCacheBuilder.create({'reason' => Constants::INTEREST_CACHE_UPDATE_REASON::NEWS_UPDATE, 'news_id' => id})
    RunningJob.create!({:job_id => job_id, :resource_id => id, :resource_type => Constants::RUNNING_JOBS::NEWS})
  end

  def self.generate_news_type_map(news_items, user)
    newstype_news_map = {}
    unique_news_items = []
    sorted_news_items = news_items.sort { |a, b| b.published_at <=> a.published_at }
    user_news_type_ids = user.interesting_news_types.collect(&:news_type_id)
    sorted_news_items.each do |news_item|
      unless unique_news_items.include? news_item
        news_type = news_item.news_type
        if news_type and user_news_type_ids.include?(news_type.id)
          if newstype_news_map.key? news_type
            newstype_news_map[news_type] << {:news_item => news_item, :companies => news_item.top_companies}
          else
            newstype_news_map[news_type] = [{:news_item => news_item, :companies => news_item.top_companies}]
          end
        end
      end
    end
    newstype_news_map
  end

  # It will return psn connections array and linkedin count
  def self.psn_li_connections(user, companies)
    li_connections_count = 0
    psn_connections = user.connections_in_companies(companies)

    li_access_token = user.generate_linkedin_access_token
    unless li_access_token.nil?
      companies.each do |company|
        result = CompanyConnectionsCount.connections_count(Constants::CONNECTIONS_COUNT_SOURCE::LINKEDIN, user, company, :access_token => li_access_token)
        li_connections_count += result[:count].to_i
      end
    end
    {:psn_connections => psn_connections, :li_count => li_connections_count}
  end

  def top_companies limit = 2
    companies.all({:limit => limit})
  end

  def self.find_by_target_interests(user, days_limit, args={})
    news = user.fetch_news(days_limit, args)
    data = news.group_by { |n| n.news_type.name }

    {:data => data, :news_count => news.count}
  end

  def self.find_by_target_companies(user, days_limit, args={})
    unique_news_ids = Set.new
    data = {}

    target_companies = user.companies.all(:limit => user.tc_limit)
    target_companies.each do |company|
      news = company.news(user, days_limit.days.ago, args)
      unless news.empty?
        data[company] = news
        unique_news_ids.merge(news.collect(&:id))
      end
    end

    summary = {
      :companies_count => data.keys.count,
      :news_count => unique_news_ids.count,
      :target_companies_count => target_companies.count
    }

    {:data => data, :summary => summary}
  end



end

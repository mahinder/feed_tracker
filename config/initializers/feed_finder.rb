require 'rubygems'
require 'rufus/scheduler'
require 'feedzirra'
require 'calais'
scheduler = Rufus::Scheduler.start_new
scheduler.cron '03 15 * * 1-7' do  
  feed_urls = FeedUrl.all
  feed_urls.each do |feed_url_obj|
    feed = Feedzirra::Feed.fetch_and_parse(feed_url_obj.feed_url)
    feed.entries.each do |entry|
      title = entry.title
      published_at = entry.published.localtime
      feed_entry = FeedEntry.new(
        :headline=>title,
        :published_at=>published_at,
        :url=> entry.url,
        :feed_url_id => feed_url_obj.id,
        :description => (entry.content || entry.summary) )
      feed_entry.save
    end
  end
end

scheduler.cron '05 15 * * 1-7' do  
  @calais_key = 'jwua5bvnh7w2m3ks3uzsy9gy'
  news_list ||= FeedEntry.pending_enrichment
  total = news_list.count
  counter = 1
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
      counter += 1
    rescue
      next
    end
    #Open calais allows only 4 transactions per second. So, we'll put a worst case delay.
    sleep(1.0/4.0)
  end
  
  
  

end


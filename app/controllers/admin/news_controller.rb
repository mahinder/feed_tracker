class Admin::NewsController < ApplicationController
  #before_filter :protect_admin_access
  load_and_authorize_resource
  layout "admin"
  require "ruby-debug"
  def news_sort_order
    "id desc"
  end

  def index
    search = params[:search]
    @news_type_options = [['- Select News Type -', nil]]
    conditions = SmartTuple.new(" AND ")
    conditions << ((search.nil? or search.strip.blank?) ? ["news.updated_at > ?", 1.month.ago] :
        ["news.updated_at > ? and headline like ?", 1.month.ago, "%#{search}%"])

    @news = News.paginate  :conditions => conditions.compile, :include => [:companies],
      :order => news_sort_order, :page => params[:page], :per_page => 100

    @initial_news_ids = @news.collect { |news| news.id }
    NewsType.all.collect { |n| @news_type_options << [n.name, n.id] }
    session[:last_updated_at] = @news.max_by(&:updated_at).updated_at if @news.present?
    session[:last_locked_at] = Time.now

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @news }
    end
  end

  # GET /news/1
  # GET /news/1.xml
  def show
    @news = News.find(params[:id])
    @people = @news.people
    @companies = @news.companies
    @tags = @news.news_indices
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @news }
    end
  end

  # GET /news/new
  # GET /news/new.xml
  def new
    @news = News.new
    @news.published_at = Time.now
    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @news }
    end
  end

  # GET /news/1/edit
  def edit
    @news = News.find params[:id]
    @people = @news.people
    @companies = @news.companies
    @tags = @news.news_indices
  end

  # POST /news
  # POST /news.xml
  def create
    News.transaction do 
      news = News.new(params[:news].merge(:user_id => current_user.id ))
      params["ready"] == "on" ? news.ready = true : news.blocked = true
      if news.save!
        news_id = news.id
        flash[:notice] = 'News was successfully created.'
        CompaniesInNews.create_company_tag(news.id, params[:companies]) if !params[:companies].blank? && params[:companies].split(' ').count < 5
        IndustriesInNews.create_industry_tag news.id, params[:industries] unless params[:industries].blank?
        Location.tag_in_news(news_id, params[:locations]) unless params[:locations].blank?
        JobTitle.tag_in_news(news_id, params[:job_titles]) unless params[:job_titles].blank?
        redirect_to admin_news_path(news)
      else
        redirect_to new_admin_news_path
      end 
    end
  end

  # PUT /news/1
  # PUT /news/1.xml
  def update
    @news = News.find(params[:id])
    render :update do |page|
      @news.clear_tags
      if @news.update_attributes(params[:news])
        flash[:notice] = 'News was successfully updated.'
        if @news.ready
          @news.on_news_update
          page << "hideBlockLockRow(#{@news.id});"
        end

        if params["commit"] == "Save and Next"
          next_news_edit_path = path_to_edit_next_news(@news.id)
          redirect_to(next_news_edit_path ? next_news_edit_path : admin_news_index_url)
        end
      else
        news_type_options = [['- Select News Type -', nil]]
        NewsType.all.collect { |n| news_type_options << [n.name, n.id] }
        message = "We are unable to save the record. Please try again with valid inputs."
        page.replace 'error', :partial => '/layouts/message_small_red', :locals => {:message => message, :id => 'error'}
        page.replace "news-#{@news.id}", :partial => 'news', :collection => [@news], :as => :news, :locals => {:max => 1, :news_type_options => news_type_options}
      end
    end
  end

  # DELETE /news/1
  # DELETE /news/1.xml
  def destroy
    @news = News.find(params[:id])
    @news.destroy
    render :json => {:news => @news.id }
  end

  def add_company
    @name = params[:company][:name]
    @news_id = params[:news_id]
    @name = @name.strip unless @name.nil?
    @news = News.find(@news_id)
    
  end

  def remove_company
    @news_id = params[:news_id]
    @company_id = params[:company_id]
  end

  def add_person
    @news = News.find params[:news_id]
    @first_name = params["first_name_#{@news.id}"]
    @last_name = params["last_name_#{@news.id}"]
    @company_name = params["company_#{@news.id}"]
  
  end

  def remove_person
    
  end

  def toggle_state
    news = News.find params[:id]
    if news.ready && params[:state] == 'block' || news.blocked && params[:state] == 'ready' || !news.blocked && !news.ready
      news.blocked = (params[:state] == 'block')
      news.ready = !news.blocked
      news.save
      render :json => {:valid => true , :news => news.id}
     
    else
      render :json => {:valid => false}
    end
  end
  def path_to_edit_next_news last_news_id
    news = News.find :last, :conditions => ["ready = 0 and blocked = 0 and id < ?", last_news_id]
    return news ? edit_admin_news_path(news) : nil
  end

  def update_news_type
    news = News.find(params[:news_id])

    news.update_attribute(:news_type_id, params[:news_type_id])
    render :nothing => true
  end

  def lock_news
    #    running_jobs = RunningJob.find(:all, :conditions => ['created_at >= ?', session[:last_locked_at]])
    running_jobs = []
    news_ids = running_jobs.collect { |job| job.resource_id }
    session[:last_locked_at] = running_jobs.empty? ? session[:last_locked_at] : running_jobs.sort_by(&:created_at).last.created_at

    render :update do |page|
      page << "lockedNewsIds = eliminateDuplicates($.merge(lockedNewsIds, #{news_ids.to_json}));"
      page << "$.each(#{news_ids.to_json}.diff(lockedNewsIds), function(_, news_id) {" +
        "if($('#news-'+news_id).find('td.cleanByBlock').length == 0) {" +
        "hideEditNewsPanel($('#' + news_id), news_id);" +
        "blockRow(news_id);" +
        "}" +
        "});"
    end
  end
  def unlock_news
    locked_news_ids = JSON.parse(params[:locked_news_ids])
    unlocked_news_ids = []
    error_msg = ''

    begin
      all_news = News.find(:all, :conditions => ['updated_at >= ?', session[:last_updated_at]])
      session[:last_updated_at] = all_news.empty? ? (session[:last_updated_at] - 5.seconds) : all_news.sort_by(&:updated_at).last.updated_at
    rescue Exception => e
      error_msg = "alert('Sorry! we are experiencing some problem on server, kindly reload the page. Contact Developers, if problem persists.')"
    end

    news_ids = all_news.collect { |news| news.id }
    all_locked_news_ids = locked_news_ids.zip(news_ids).flatten.compact.uniq

    render :update do |page|
      page << error_msg
      all_locked_news_ids.each do |news_id|
        if RunningJob.find_by_resource_id_and_resource_type(news_id, 1).nil?
          news_type_options = [['- Select News Type -', nil]]
          NewsType.all.collect { |n| news_type_options << [n.name, n.id] }
          page.replace "news-#{news_id}", :partial => 'news', :collection => [News.find(news_id)], :as => :news, :locals => {:max => 1, :news_type_options => news_type_options}
          unlocked_news_ids << news_id
        end
      end
      page << "lockedNewsIds = lockedNewsIds.diff(#{unlocked_news_ids.to_json});"
    end
  end

  def hide_destroyed_news
    init_ids = JSON.parse(params[:initial_news_ids])
    curr_news = News.find_all_by_id(init_ids)
    if curr_news != init_ids.count
      curr_news_ids = curr_news.collect { |news| news.id }
      del_news = init_ids - curr_news_ids
    end

    render :update do |page|
      del_news.each do |news_id|
        page.visual_effect :fade, "tbody#news-#{news_id}"
        page << "initialNewsIds.remove(#{news_id});"
      end
    end
  end

  # Export the Linksv News in to CSV file, since last week
  def export
    ns = NewsSource.find_by_name 'Linksv', :select => :id
    @news = News.find(:all, :conditions => ["updated_at >= ? and news_source_id != ? and ready = 1", 1.week.ago, ns.id])
    file_name = "linksv_news_#{1.week.ago.strftime('%b-%d-%Y')}_to_#{Time.now.strftime('%b-%d-%Y')}.csv"
    csv = %w(Source Headline).to_csv
    @news.each { |news| csv << [news.news_source.name, news.news_headline].to_csv }
    send_data csv, :filename => file_name, :type => "text/csv"
  end

  def news_dashboard
    from = params[:from]
    to = params[:to]
    flash[:notice] = false
    if to.blank? or from.blank?
      flash[:notice] = "Please select duration"
    else
      @days = (from.to_date..to.to_date).map { |date| date.strftime("%Y-%m-%d") }
    end
    respond_to do |format|
      format.html
    end
  end

  def news_data 
    date = params[:day]
    all_sources_count = []
    news_sources = NewsSource.all
    news_sources.each do |news_source|
      source_name = news_source.name
      news_count_by_creation_date = news_source.news.count(:conditions => ["DATE(news.created_at) = ?", date])
      news_count_by_publish_date = news_source.news.count(:conditions => ["DATE(news.created_at) = ? and DATE(news.published_at) = ?", date, date])
      all_news = {:news_count_by_creation_date => news_count_by_creation_date,
        :news_count_by_publish_date => news_count_by_publish_date, :source_name => source_name}
      all_sources_count << all_news
    end

    joins = "INNER JOIN  interesting_news on interesting_news.news_id = news.id"
    group_by = "interesting_news.news_id"

    int_news_by_creation_date = News.find(:all, :select => "news.id",
      :conditions => ["DATE(news.created_at) = ?", date],
      :joins => joins,
      :group => group_by)

    int_news_by_publish_date = News.find(:all, :select => "news.id",
      :conditions => ["DATE(news.created_at) = ? and DATE(news.published_at) = ?", date, date],
      :joins => joins,
      :group => group_by)

    email_alert_count = User.count(:conditions => ["DATE(news_emailed_at) = ?", (date.to_date + 1)])

    news_type_data = NewsType.news_type_data(date)

    render :update do |page|
      page.show('.data-area')
      page.replace_html "news-source-data", :partial => 'admin/news/news_source_data',
        :locals => {:all_sources_count => all_sources_count, :day => date}
      page.replace_html "interesting-news-data", :partial => 'admin/news/interesting_news_data',
        :locals => {:int_news_by_creation_date_count => int_news_by_creation_date.count, :int_news_by_publish_date_count => int_news_by_publish_date.count}
      page.replace_html "news-type-data", :partial => 'admin/news/news_type_data',
        :locals => {:news_type_data => news_type_data, :email_alert_count => email_alert_count}
      page.replace_html "alert-send-data", :partial => 'admin/news/news_alerts_data', :locals => {:email_alert_count => email_alert_count}
      page.hide('progress_div')
    end
  end

 
  
  
  
end

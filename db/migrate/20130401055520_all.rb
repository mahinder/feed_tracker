class All < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name, :limit => 255
      t.string :url, :limit => 1024
      t.string :phone1
      t.string :phone2
      t.string :fax
      t.string :street1
      t.string :street2
      t.string :city
      t.string :state
      t.string :zip
      t.integer :country_id, :default => 1
      t.timestamps
    end

    create_table :domains do |t|
      t.string :name
      t.timestamps
    end
    
    add_column :companies, :domain_id, :integer
    companies = Company.all
    companies.each { |company|
      unless company == nil or company.url ==nil or company.url.strip.blank?
        begin
          url = company.url
          domain_name = Company.get_domain(url)
          unless domain_name == nil or domain_name.strip.blank?
            # Use a similar domain from database if it exists else create new.
            domain = Domain.find(:first,:conditions => ["name like ?",domain_name] )
            domain = Domain.create(:name => domain_name ) if domain.nil?
            if domain
              company.domain_id = domain.id
              company.save
            end
          end
        rescue
          puts "A problem occurred while storing domain name of company #{company.id}"
        end
      end
      
    }
    create_table :news do |t|
      t.integer :user_id
      t.string :headline
      t.datetime :published_at
      t.string :url
      t.text :description
      t.boolean :is_enriched , :default => false
      t.references :news_feed
      t.string :reason
      t.text :calais_data
      t.string :feed_domain
      t.timestamps
    end
    add_column :news, :blocked, :boolean, :default=>false
    add_column :news, :ready, :boolean, :default=>false
     
    create_table :designations do |t|
      t.string :name
    end
    
    create_table :people do |t|
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :email
      t.integer :current_company_id
      t.integer :last_company_id
      t.integer :current_designation_id
      t.integer :last_designation_id
      t.timestamps
    end
    
    create_table :news_indices do |t|
      t.integer :news_id
      t.string :tag
      t.string :value
      t.datetime :created_at
    end
    add_index :news_indices, :tag
    
    create_table :people_in_news do |t|
      t.integer :news_id
      t.integer :person_id
    end
    
    create_table :companies_in_news do |t|
      t.integer :news_id
      t.integer :company_id
    end
    create_table :industries do |t|
      t.string :name
    end
    Industry.fill_it_up
    add_index :industries,:name
    
    
    create_table :locations do |t|
      t.string :name
    end
    
    create_table :job_titles do |t|
      t.string :name
    end
    
    create_table :job_functions do |t|
      t.string :name
    end
    create_table :news_types do |t|
      t.string :name
    end
    
    create_table :industries_in_news do |t|
      t.integer :news_id
      t.integer :industry_id
    end
    
    create_table :locations_in_news do |t|
      t.integer :news_id
      t.integer :location_id
    end
    create_table :job_titles_in_news do |t|
      t.integer :news_id
      t.integer :job_title_id
    end
    
    create_table :job_functions_in_news do |t|
      t.integer :news_id
      t.integer :job_function_id
    end
    create_table :news_feed_default_industries do |t|
      t.integer :news_feed_id
      t.integer :industry_id
    end
    create_table :news_feed_default_locations do |t|
      t.integer :news_feed_id
      t.integer :location_id
    end
    add_column :companies, :lookup_signature, :string
    #    add_column :company_templates, :lookup_signature, :string
    add_index :companies, :lookup_signature, :name => 'ix_cmp_lookup_sign'
    
    create_table :verified_companies do |t|
      t.string :name
      t.string :lookup_signature
      t.integer :company_template_id

      t.timestamps
    end

    add_index :verified_companies, :name, :unique => true
    add_index :verified_companies, :lookup_signature
    
    add_column :companies, :verified_company_id, :integer
    add_index :companies, :verified_company_id, :name => 'ix_comp_verified_comp_id'
    add_column :companies, :display_name, :string
    
    add_column :verified_companies, :domain_id, :integer
    add_index :verified_companies, :domain_id
    
    create_table :users do |t|
      t.string  :user_name
      t.boolean :is_admin
      t.timestamps
    end
    
    create_table :api_keys do |t|
      t.string :access_token
      t.references :user
      t.string :organisation_key

      t.timestamps
    end
    
    create_table :news_feeds do |t|
      t.references :user
      t.integer :news_type_id
      t.string :feed_url
      t.timestamps
    end
    
    add_column :news, :news_type_id, :integer
    news = News.find :all,:select=>"DISTINCT reason"
    news.each do |news_item|
      reason = news_item.reason
      type = nil
      case reason
      when 'Recent Funding','Recently funded',' Venture Funded','Venture Funded','Financing'
        type = NewsType.find_by_name 'Recently funded'
      else
        type = NewsType.find_by_name reason
      end
      News.update_all "news_type_id = #{type.id}","reason = '#{reason}'" unless type.nil?
    end
    
    add_column :news, :industry_id, :integer
    add_column :news, :location, :string
    add_index :news,:location
    
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
    remove_column(:news, :location,:industry_id)
    create_table :interesting_news do |t| 
      t.integer :user_id
      t.integer :news_id
    end
    add_column :news_feeds, :tagged_for, :text
    add_column :news_feeds, :scope,:string  
    
    
  end
end

require 'company_lookup_signature'
# Company class has code that relates to 'companies' table.
class Company < ActiveRecord::Base
  #  has_many :prospects, :class_name => "Contact", :foreign_key => "company_id", :conditions => ["contact_type <> ?", Constants::CONTACT_TYPE::CONTACT]
  belongs_to :user
  belongs_to :verified_company
  has_one :domain
  before_save :update_url_domain, :add_or_update_lookup_signature
#  after_save :update_contact_company_name
  before_create :link_to_verified_companies
  # A company has many contacts
  has_many :contacts
  has_one :title
  has_many :target_companies
  has_many :users, :through => :target_companies
  after_destroy :clear_linkedin_count_cache
  validates :name ,:presence => true , :uniqueness => {:case_sensitive => false}
 
  def info
    if verified_company_id
      CompanyTemplate.first :joins => 'inner join verified_companies on company_templates.id = verified_companies.company_template_id',
        :conditions => "verified_companies.id = #{verified_company_id}"
    else
      self
    end
  end

  def name
    if display_name
      display_name
    else
      read_attribute(:name)
    end
  end

  def name=(name)
    write_attribute(:name, name.squish)
  end

  def self.find_unique name
    if name.nil?
      nil
    else
      name = name.squish
      if name.blank?
        nil
      else
        lookup_signature = name.company_lookup_signature
        vc = VerifiedCompany.find_by_lookup_signature lookup_signature
        name = vc.name if vc
        Company.find_or_create_by_name name
      end
    end
  end

  #Check interesting_sizes for empty before calling
  def interesting_by_size? interesting_sizes
    interesting_sizes.each do |size|
      return true if size.match? self
    end
    return false
  end

  #Check interesting_revenues for empty before calling
  def interesting_by_revenue? interesting_revenues
    interesting_revenues.each do |revenue|
      return true if revenue.match? self
    end
    return false
  end

  def interesting_by_size_and_revenue? interesting_sizes, interesting_revenues
    return ((interesting_sizes.empty? or self.interesting_by_size?(interesting_sizes)) and
        (interesting_revenues.empty? or self.interesting_by_revenue?(interesting_revenues))) ? true : false
  end

  def matching_company_ids
    companies = Company.find :all, :select => "id", :conditions => company_lookup_condition
    companies.collect { |company| company.id }
  end

  def company_lookup_condition
    condition = SmartTuple.new(" OR ")
    condition << {:lookup_signature => self.lookup_signature}
    condition << {:domain_id => self.domain_id} unless self.domain_id.nil?
    condition.compile
  end

  def clear_linkedin_count_cache
    CompanyConnectionsCount.destroy_all :company_id => self.id
  end

  def clear_info
    self.update_attributes(
      :url => nil,
      :phone1 => nil,
      :phone2 => nil,
      :fax => nil,
      :street1 => nil,
      :street2 => nil,
      :city => nil,
      :state => nil,
      :zip => nil,
      :country => nil,
      :employees => nil,
      :revenue => nil,
      :industry => nil,
      :sic_code => nil,
      :location => nil,
      :ticker => nil,
      :stock_symbol => nil,
      :stock_exchange => nil,
      :ownership => nil,
      :employee_range => nil,
      :revenue_range => nil,
      :industry2 => nil,
      :industry3 => nil,
      :sub_industry => nil,
      :sub_industry2 => nil,
      :sub_industry3 => nil,
      :jigsaw_flagged => 0,
      :domain_id => nil
    )
  end

  def has_connections? user_id
    connection = Connection.find(:first, :select => "`connections`.id",
      :joins => "INNER join contacts `contacts`  on `contacts`.id = `connections`.contact_id
                                            INNER join titles titles on contacts.id = titles.contact_id
                                            INNER join companies companies on titles.company_id = companies.id",
      :conditions => ["`connections`.user_id=? AND `titles`.company_id in (?)", user_id, self.matching_company_ids])
    connection ? true : false
  end

  def news(user, from_date, args={})
    conditions = SmartTuple.new(" AND ")
    conditions << ["interesting_news.user_id = ? AND ready = 1
                         AND `companies_in_news`.company_id IN (?)
                         AND published_at > ?", user.id, matching_company_ids, from_date]
    conditions << ["news.headline like ?", "%#{args[:search]}%"] if args[:search]

    News.all(
      :select => "news.id, news.headline,news.reason, news.url, news.news_type_id, news.origin_domain, updated_at, published_at",
      :order => "DATE(news.published_at) desc",
      :joins => "INNER JOIN interesting_news on interesting_news.news_id = news.id
                   INNER JOIN `companies_in_news` ON `companies_in_news`.news_id = `news`.id",
      :conditions => conditions.compile
    )
  end

  def formated_url
    furl = self.url
    if !furl.blank? and !furl.match(/^[http\:\/\/]/) and !furl.match(/^[https\:\/\/]/)
      furl = 'http://' + furl
    end
    return furl
  end

  def merge_company_data(data)
    is_merged = false
    website = "#{data.website}"
    unless website.strip.blank?
      if self.url.blank?
        self.url = website
        is_merged = true
      end
    end
    cphone = "#{data.company_phone}"
    unless cphone.strip.blank?
      if self.phone1.blank?
        self.phone1 = cphone
        is_merged = true
      end
    end
    cfax = "#{data.company_fax}"
    unless cfax.strip.blank?
      if self.fax.blank?
        self.fax = cfax
        is_merged = true
      end
    end
    cst1 = "#{data.company_street1}"
    unless cst1.strip.blank?
      if self.street1.blank?
        self.street1 = cst1
        is_merged = true
      end
    end
    cst2 = "#{data.company_street2}"
    unless cst2.strip.blank?
      if self.street2.blank?
        self.street2 = cst2
        is_merged = true
      end
    end
    ccity = "#{data.company_city}"
    unless ccity.strip.blank?
      if self.city.blank?
        self.city = ccity
        is_merged = true
      end
    end
    cstate = "#{data.company_state}"
    unless cstate.strip.blank?
      if self.state.blank?
        self.state = cstate
        is_merged = true
      end
    end
    czip = "#{data.company_zip}"
    unless czip.strip.blank?
      if self.zip.blank?
        self.zip = czip
        is_merged = true
      end
    end
    ccountry = "#{data.company_country}"
    unless ccountry.strip.blank?
      if self.country.blank?
        self.country = ccountry
        is_merged = true
      end
    end
    return is_merged
  end

  def merge_outlook_company_data(data)
    is_merged = false
    cphone = "#{data[:company_main_phone]}"
    unless cphone.strip.blank?
      if self.phone1.blank?
        self.phone1 = cphone
        is_merged = true
      end
    end
    cfax = "#{data[:business_fax]}"
    unless cfax.strip.blank?
      if self.fax.blank?
        self.fax = cfax
        is_merged = true
      end
    end
    cst1 = "#{data[:business_street]}"
    unless cst1.strip.blank?
      if self.street1.blank?
        self.street1 = cst1
        is_merged = true
      end
    end
    cst2 = "#{data[:business_street_2]}"
    unless cst2.strip.blank?
      if self.street2.blank?
        self.street2 = cst2
        is_merged = true
      end
    end
    ccity = "#{data[:business_city]}"
    unless ccity.strip.blank?
      if self.city.blank?
        self.city = ccity
        is_merged = true
      end
    end
    cstate = "#{data[:business_state]}"
    unless cstate.strip.blank?
      if self.state.blank?
        self.state = cstate
        is_merged = true
      end
    end
    czip = "#{data[:business_postal_code]}"
    unless czip.strip.blank?
      if self.zip.blank?
        self.zip = czip
        is_merged = true
      end
    end
    ccountry = "#{data[:business_countryregion]}"
    unless ccountry.strip.blank?
      if self.country.blank?
        self.country = ccountry
        is_merged = true
      end
    end
    return is_merged
  end

  def append_jsw_data(jsw_attr_hash)
    company_info = JSON.parse(self.to_json)["company"]
    unless company_info.nil?
      vkeys = company_info.select { |k, v| v && !v.to_s.strip.empty? }.collect { |k| k[0] }
      jsw_attr_hash.reject! { |k, v| vkeys.include?(k) }
      self.update_attributes(jsw_attr_hash)
    end
  end

  def self.maintenance_csv_header
    ["id (read-only)", "name", "url", "domain id (Read-only)", "merge into id"]
  end

  def maintenance_csv_row
    [
      "#{self.id}",
      "#{self.name}",
      "#{self.url}",
      "#{self.domain_id}",
      ""
    ]
  end

  def self.safe_destruction ids, update_references_to_this_id
    Company.transaction do
      CompaniesInNews.update_all "company_id = #{update_references_to_this_id}", ["company_id in (?)", ids]
      CompanyConnectionsCount.update_all "company_id = #{update_references_to_this_id}", ["company_id in (?)", ids]
      Contact.update_all "company_id = #{update_references_to_this_id}", ["company_id in (?)", ids]
      TargetCompany.update_all "company_id = #{update_references_to_this_id}", ["company_id in (?)", ids]
      Person.update_all("current_company_id = #{update_references_to_this_id}", ["current_company_id in (?)", ids])
      Person.update_all("last_company_id = #{update_references_to_this_id}", ["last_company_id in (?)", ids])
      Company.destroy_all ["id in (?)", ids]
    end
  end

  private
  def update_contact_company_name
    Contact.update_all("company_name = '#{self.name}'", "company_id = #{self.id}")
  rescue
    # this will handle the company names with (')
    cts = Contact.find(:all, :conditions => ["company_id = #{self.id}"])
    cts.each do |d|
      d.update_attribute(:company_name, self.name)
    end
  end

  def add_or_update_lookup_signature
    self.lookup_signature = self.name.company_lookup_signature
  end

  def update_url_domain
    unless self.url == nil or self.url.strip.blank?
      begin
        domain_name = HttpHelper.get_domain(self.url)
        unless domain_name == nil or domain_name.strip.blank?
          # Use a similar domain from database if it exists else create new.
          domain = Domain.find(:first, :conditions => ["name like ?", domain_name])
          if domain == nil
            domain = Domain.create(:name => domain_name)
          end
          if domain
            self.domain_id = domain.id
          end
        end
      rescue
        puts "A problem occurred while storing domain name of company #{self.id}"
      end
    end
  end

  def link_to_verified_companies
    if self.verified_company_id.nil?
      condition = SmartTuple.new(" OR ")
      condition << {:lookup_signature => self.lookup_signature}
      condition << {:domain_id => self.domain_id} unless self.domain_id.nil?

      vc = VerifiedCompany.find :first, :conditions => condition.compile, :select => 'id, name'
      unless vc.nil?
        self.verified_company_id = vc.id
        self.display_name = vc.name
      end
    end
  end
end

# Contact class has code that relates to 'contacts' table.
class Contact < ActiveRecord::Base
#  include Constants
  # Every contact belongs to a user, may or may not have a company, facebook_status, linkedin_status. A contact can have many emails, meta information, sources
  belongs_to :user
  belongs_to :company

  belongs_to :facebook_status
  belongs_to :linkedin_status

  has_one :top_connector

  has_one :shared_contact_prospect_priority

  has_many :emails, :dependent => :destroy
  has_many :contact_metas, :dependent => :destroy
  has_many :titles, :dependent => :destroy

  has_many :contact_prospects
  has_many :prospects, :through => :contact_prospects, :source => :prospect

  has_many :firsthop_prospects, :class_name => 'ContactProspect', :foreign_key => 'prospect_id'
  has_many :firsthops, :through => :firsthop_prospects, :source => :contact

  has_and_belongs_to_many :sources

  has_many :emails, :dependent => :destroy
  has_many :contact_metas, :dependent => :destroy
  has_and_belongs_to_many :sources

  after_create :create_connections
  before_update :update_connections
  before_destroy :destroy_connections


  public
  # Method combines First name, Last name and returns Full Name of Contact
  def name
    name = ''
    name = first_name if first_name
    name = name + ' ' + last_name if last_name
    name
  end

  def name=(val)
    arr = val.split(' ').compact
    write_attribute(:first_name, arr.delete(arr.first)) unless arr.empty?
    write_attribute(:last_name, arr.delete(arr.last)) unless arr.empty?
    write_attribute(:middel_name, arr.join(' ')) unless arr.empty?
  end

  # Method combines First name, Middle name & Last name and returns Full Name of Contact
  def full_name
    return Contact.generate_full_name self.first_name, self.middel_name, self.last_name
  end

  def full_name_or_email
    name = Contact.generate_full_name self.first_name, self.middel_name, self.last_name
    name.blank? ? Contact.get_default_email(self.id) : name
  end

  def get_target_company
    return TargetCompany.find(:first, :conditions => ["company_id = ? AND user_id = ?", self.company_id, self.user_id])
  end

  def self.generate_full_name first_name, middle_name, last_name
    name = ''
    name = first_name if first_name
    name = name + ' ' + middle_name if middle_name
    name = name + ' ' + last_name if last_name
    return name.titlecase
  end

  def self.create_from_f3_user(context_user, owner_id)
    company_name = context_user.company_name
    company_id = 0
    unless company_name.nil?
      company_name = company_name.strip
      unless company_name.blank?
        company = Company.find_or_create_by_name company_name
        company_id = company.id
      end
    end

    transaction do
      new_contact = Contact.create(
          :first_name => context_user.first_name,
          :last_name => context_user.last_name,
          :company_id => company_id,
          :user_id => owner_id)

      source = Source.find_by_name("Sharing")
      new_contact.sources << source unless source.nil?

      new_contact.emails.create(:email_text => context_user.email, :source_id => source.id) unless source.nil?
      return new_contact
    end
  end

  def get_display_pic generate_absolute_path = false
    pic = self.display_pic
    if pic.nil?
      if self.facebook_status_id == 1
        meta = ContactMeta.find_by_contact_id(self.id)
        unless meta.nil? or meta.fb_uid.nil?
          pic = "https://graph.facebook.com/#{meta.fb_uid}/picture"
        end
      end
    end
    return Contact.get_display_pic(pic, generate_absolute_path)
  end

  def self.get_display_pic display_pic_url, generate_absolute_path = false
    if display_pic_url.nil? or display_pic_url.strip.blank?
      if generate_absolute_path
        return "http://#{AppConfig["base_url"]}/images/no_pic.gif"
      else
        return 'no_pic.gif'
      end
    else
      return display_pic_url
    end
  end

  def get_rainmaker_id
    li_id = self.get_linkedin_id
    if li_id
      tpa = ThirdPartyAuthentication.find(:first,
                                          :select => "user_id",
                                          :conditions => ["third_party_user_id = ? and provider = ?", li_id, Constants::AUTH_PROVIDER::LINKEDIN])
      return tpa.user_id unless tpa.nil?
    end
    my_emails = self.emails.all
    my_emails.each do |my_email|
      user = User.find_by_email(my_email.email_text)
      if user != nil
        return user.id
      end
    end
    return 0
  end

  def get_linkedin_id
    meta = ContactMeta.find(:first, :select => "linkedin_id", :conditions => ["linkedin_id is not null and contact_id = ?", self.id])
    return meta ? meta.linkedin_id : nil
  end

  def add_to_top_connector
    #tp_status = contact.contact_prospects.empty? ? TOP_CONNECTOR_STATUS::NotStarted : TOP_CONNECTOR_STATUS::InProcess
    TopConnector.create(:contact_id => self.id, :network => false)
    if self.fm_status.blank?
      self.update_attribute(:fm_status, TOP_CONNECTOR_STATUS::NotStarted)
    end
  end

  # Method returns Primary Email of a contact if any or blank otherwise
  def email
    return Contact.get_default_email self.id
  end

  def self.get_default_email contact_id
    found_emails = Email.find_all_by_contact_id(contact_id, :select => "email_text,is_primary")

    if found_emails.nil? or found_emails.empty?
      ''
    else
      if found_emails.count == 1
        found_emails.first.email_text
      else
        found_emails.each do |email|
          if email.is_primary?
            return email.email_text
          end
        end
        return found_emails.first.email_text
      end
    end
  end

  # Method returns the Count of Total Non Suspended Contacts for a user
  def self.total_count(user_id)
    count(:conditions => ["contacts.is_suspended = 0 AND user_id = ? AND merged_to_form_contact_id = 0 AND contacts.contact_type <> ? ", user_id, CONTACT_TYPE::PROSPECT])
  end

  # Method returns the Count of Facebook Non Suspended Contacts for a user
  def self.facebook_count(user_id)
    count(:include => [:sources], :conditions => ["contacts.is_suspended = 0 AND sources.id = 1 AND user_id = ? AND merged_to_form_contact_id = 0", user_id])
  end

  # Method returns the Count of LinkedIN Non Suspended Contacts for a user
  def self.linked_in_count(user_id)
    count(:include => [:sources], :conditions => ["contacts.is_suspended = 0 AND sources.id = 2 AND user_id = ? AND merged_to_form_contact_id = 0", user_id])
  end

  # Method returns the Count of Gmail Non Suspended Contacts for a user
  def self.gmail_count(user_id)
    count(:include => [:sources], :conditions => ["contacts.is_suspended = 0 AND sources.id = 3 AND user_id = ? AND merged_to_form_contact_id = 0", user_id])
  end

  # Method returns the Count of Yahoo Non Suspended Contacts for a user
  def self.yahoo_count(user_id)
    count(:include => [:sources], :conditions => ["contacts.is_suspended = 0 AND sources.id = 4 AND user_id = ? AND merged_to_form_contact_id = 0", user_id])
  end

  # Method returns the Count of CSV Non Suspended Contacts for a user
  def self.csv_count(user_id)
    count(:include => [:sources], :conditions => ["contacts.is_suspended = 0 AND sources.id = 5 AND user_id = ? AND merged_to_form_contact_id = 0", user_id])
  end

  # Method returns the Count of PDF Non Suspended Contacts for a user
  def self.pdf_count(user_id)
    count(:include => [:sources], :conditions => ["contacts.is_suspended = 0 AND sources.id = 6 AND user_id = ? AND merged_to_form_contact_id = 0", user_id])
  end

  # Method returns the Count of BizCard Non Suspended Contacts for a user
  def self.bcards_count(user_id)
    count(:include => [:sources], :conditions => ["contacts.is_suspended = 0 AND sources.id = 7 AND user_id = ? AND merged_to_form_contact_id = 0", user_id])
  end

  # Method returns the Count of Outlook Non Suspended Contacts for a user
  def self.outlook_count(user_id)
    count(:include => [:sources], :conditions => ["contacts.is_suspended = 0 AND sources.id = 10 AND user_id = ? AND merged_to_form_contact_id = 0", user_id])
  end

  # Method returns the Count of Manually added Non Suspended Contacts for a user
  def self.manual_count(user_id)
    count(:include => [:sources], :conditions => ["contacts.is_suspended = 0 AND sources.id = 8 AND user_id = ? AND merged_to_form_contact_id = 0", user_id])
  end

  # Method returns the Count of Other Non Suspended Contacts for a user
  def self.others_count(user_id)
    count(:include => [:sources], :conditions => ["contacts.is_suspended = 0 AND sources.id = 9 AND user_id = ? AND merged_to_form_contact_id = 0", user_id])
  end

  # Method returns the Count of all sources (except facebook,linkedin,outlook) Non Suspended Contacts for a user
  def self.other_sources_count(user_id)
    count(:include => [:sources], :conditions => ["contacts.is_suspended = 0 AND sources.id IN ( 13,9,8,7,6,5,4,3 ) AND user_id = ? AND merged_to_form_contact_id = 0", user_id])
  end

  # Method was for OneTime updating of all contacts FB Status, LI status
  def self.set_newtwork_status_once
    update_all("facebook_status_id = 1", "source_id = 1")
    update_all("linkedin_status_id = 1", "source_id = 2")
  end

  # Method returns the top connector status of Contact
  def is_top_connector?
    TopConnector.exists? :contact_id => self.id
  end

  def is_sharing?
    Share.exists? :user_id => self.user_id, :contact_id => self.id
  end

  def sharing_status_code
    share = Share.find_by_user_id_and_contact_id(self.user_id, self.id, :select => "status_code")
    return share.nil? ? nil :share.status_code
  end

  def has_prospects?
    return Connection.exists? :user_id => self.user_id, :hop_id => self.id
  end

  def is_sharing_request_pending_approval? current_user_id
    Share.exists? :user_id => current_user_id, :contact_id => self.id, :status_code => Constants::SHARE_STATUS_CODE::REQUESTED
  end

  # Method validates a Contact for Manual Entry
  def validate?
    valid = true
    if first_name.blank? && last_name.blank?
      errors.add_to_base("Must enter contact name")
      valid = false
    end
    ex_email = Contact.find(:first, :include => [:emails], :conditions => ["emails.email_text = ? AND contacts.user_id = ? AND merged_to_form_contact_id = 0", self.email, self.user_id])
    if ex_email
      errors.add_to_base("Contact already in network")
      valid = false
    end
    valid
  end

  # Method validates a Contact for Manual Update
  def validated_for_update?(c)
    valid = true
    if first_name.blank? && last_name.blank?
      c.errors.add_to_base("Must enter contact name")
      valid = false
    end
    ex_email = Contact.find(:first, :include => [:emails], :conditions => ["emails.email_text = ? AND contacts.user_id = ? AND contacts.id != ? AND merged_to_form_contact_id = 0", email, user_id, c.id])
    if ex_email
      c.errors.add_to_base("Contact already in network")
      valid = false
    end
    valid
  end

  def merge_contact_with_new_gmail_data(contact)
    merged = false
    unless contact.first_name.blank?
      if self.first_name.blank?
        self.first_name = contact.first_name
        merged = true
      end
    end
    unless contact.last_name.blank?
      if self.last_name.blank?
        self.last_name = contact.last_name
        merged = true
      end
    end
    return merged
  end


  def merge_contact_with_new_yahoo_data(contact_xml)
    save_point_flag = false
    contact_xml.elements['contact'].elements.each('fields') do |field|
      case field.elements['type'].text
        when 'email'
          ev = "#{field.elements["value"].text}"
          unless ev.strip.blank?
            if self.email.blank?
              self.email = ev
              save_point_flag = true
            end
          end
        when 'jobTitle'
          jv = "#{field.elements["value"].text}"
          unless jv.strip.blank?
            if self.title.blank?
              self.title = jv
              save_point_flag = true
            end
          end
        when 'address'
          asv = "#{field.elements["value"].elements["street"].text}"
          unless asv.strip.blank?
            if self.street1.blank?
              self.street1 = asv
              save_point_flag = true
            end
          end
          acv = "#{field.elements["value"].elements["city"].text}"
          unless acv.strip.blank?
            if self.city.blank?
              self.city = acv
              save_point_flag = true
            end
          end
          aspv = "#{field.elements["value"].elements["stateOrProvince"].text}"
          unless aspv.strip.blank?
            if self.state.blank?
              self.state = aspv
              save_point_flag = true
            end
          end
          actv = "#{field.elements["value"].elements["country"].text}"
          unless actv.strip.blank?
            if self.country.blank?
              self.country = actv
              save_point_flag = true
            end
          end
          azv = "#{field.elements["value"].elements["postalCode"].text}"
          unless azv.strip.blank?
            if self.zip.blank?
              self.zip = azv
              save_point_flag = true
            end
          end
        when 'phone'
          pv = "#{field.elements["value"].text}"
          unless pv.strip.blank?
            if self.phone.blank?
              self.phone = pv
              save_point_flag = true
            end
          end
        when 'name'
          ngv = "#{field.elements["value"].elements["givenName"].text}"
          unless ngv.strip.blank?
            if self.first_name.blank?
              self.first_name = ngv
              save_point_flag = true
            end
          end
          nfv = "#{field.elements["value"].elements["familyName"].text}"
          unless nfv.strip.blank?
            if self.last_name.blank?
              self.last_name = nfv
              save_point_flag = true
            end
          end
        else
          logger.info "unknown filed type....#{field.elements['type'].text}"
      end
    end
    return save_point_flag
  end

  def merge_contact_with_new_csv_data(data)
    is_merged = false
    #~ fnv = "#{data[:first_name]}"
    fnv = "#{data.first_name}"
    unless fnv.strip.blank?
      if self.first_name.blank?
        self.first_name = fnv
        is_merged = true
      end
    end
    lnv = "#{data.last_name}"
    unless lnv.strip.blank?
      if self.last_name.blank?
        self.last_name = lnv
        is_merged = true
      end
    end

    dtv = "#{data.title}"
    unless dtv.strip.blank?
      if self.title.blank?
        self.title = dtv
        is_merged = true
      end
    end

    s1v = "#{data.street1}"
    unless s1v.strip.blank?
      if self.street1.blank?
        self.street1 = s1v
        is_merged = true
      end
    end

    s2v = "#{data.street2}"
    unless s2v.strip.blank?
      if self.street2.blank?
        self.street2 = s2v
        is_merged = true
      end
    end

    ctv = "#{data.city}"
    unless ctv.strip.blank?
      if self.city.blank?
        self.city = ctv
        is_merged = true
      end
    end

    stv = "#{data.state}"
    unless stv.strip.blank?
      if self.state.blank?
        self.state = stv
        is_merged = true
      end
    end

    cuv = "#{data.country}"
    unless cuv.strip.blank?
      if self.country.blank?
        self.country = cuv
        is_merged = true
      end
    end

    zv = "#{data.zip}"
    unless zv.strip.blank?
      if self.zip.blank?
        self.zip = zv
        is_merged = true
      end
    end
    return is_merged
  end

  def merge_contact_with_outlook_data(data)
    is_merged = false
    fnv = "#{data[:first_name]}"
    unless fnv.strip.blank?
      if self.first_name.blank?
        self.first_name = fnv.strip
        is_merged = true
      end
    end
    lnv = "#{data[:last_name]}"
    unless lnv.strip.blank?
      if self.last_name.blank?
        self.last_name = lnv.strip
        is_merged = true
      end
    end
    dtv = "#{data[:job_title]}"
    unless dtv.strip.blank?
      if self.title.blank?
        self.title = dtv.strip
        is_merged = true
      end
    end

    ppv = "#{data[:primary_phone]}"
    unless ppv.strip.blank?
      if self.phone.blank?
        self.phone = ppv.strip
        is_merged = true
      end
    end

    mpv = "#{data[:mobile_phone]}"
    unless mpv.strip.blank?
      if self.mobile_phone.blank?
        self.mobile_phone = mpv.strip
        is_merged = true
      end
    end

    hsv1 = "#{data[:home_street]}"
    unless hsv1.strip.blank?
      if self.street1.blank?
        self.street1 = hsv1.strip
        is_merged = true
      end
    end

    hsv2 = "#{data[:home_street_2]}"
    unless hsv2.strip.blank?
      if self.street2.blank?
        self.street2 = hsv2.strip
        is_merged = true
      end
    end

    hcn = "#{data[:home_city]}"
    unless hcn.strip.blank?
      if self.city.blank?
        self.city = hcn.strip
        is_merged = true
      end
    end

    stv = "#{data[:home_state]}"
    unless stv.strip.blank?
      if self.state.blank?
        self.state = stv.strip
        is_merged = true
      end
    end

    cuvr = "#{data[:home_countryregion]}"
    unless cuvr.strip.blank?
      if self.country.blank?
        self.country = cuvr.strip
        is_merged = true
      end
    end

    hzv = "#{data[:home_postal_code]}"
    unless hzv.strip.blank?
      if self.zip.blank?
        self.zip = hzv.strip
        is_merged = true
      end
    end
    return is_merged
  end

  # Method to bulk populate contact sources, when we moved to Multiple sources per Contact from the previous single Source per contact.
  def self.populate_source_ids
    find(:all).each do |c|
      unless c.source_id.blank?
        c.sources << Source.find(c.source_id)
      end
    end
  end

  # Method to bulk populate emails, when we moved to Multiple emails per Contact from the previous single Email per contact.
  def self.populate_emails
    find(:all).each do |c|
      unless c.email.blank?
        c.emails.create(:email_text => c.email, :source_id => c.sources[0].id)
      end
    end
  end

  # Method Returns Collection of Contacts that are suspected as duplicates in the Merge but not Merged. THis scenario does not occur now.
  def duplicates
    Contact.find(:all, :conditions => ["id != ? AND merge_id = ?", id, merge_id])
  end

  # Method Returns Collection of Contacts that were Merged to form the calling Contact
  def parents
    Contact.find(:all, :conditions => ["merged_to_form_contact_id = ?", self.id])
  end

  # Method To Unmerge Contact
  def un_merge
    Contact.transaction do
      self.parents.each do |contact|
        contact.update_attribute('merged_to_form_contact_id', 0)
        if contact.contact_type == Constants::CONTACT_TYPE::PROSPECT
          ContactProspect.update_all("prospect_old_id = NULL, prospect_id = #{contact.id}", "prospect_old_id = #{contact.id}")
        else
          ContactProspect.update_all("contact_old_id = NULL, contact_id = #{contact.id}", "contact_old_id = #{contact.id}")
        end
      end
      self.emails.clear
      self.sources.clear
      self.contact_metas.clear
      self.destroy_shares
      self.destroy

    end
  end

  def prospect_priority(pid)
    #contact_prospects.find(:first, :conditions => ["prospect_id = ?", pid]).fm_priority_id
  end

  def self.do_update_once
    Email.all.each do |em|
      puts "updating email ... #{em.id}"
      em.update_attribute(:created_at, em.created_at)
    end
    Company.all.each do |cm|
      puts "updating company ... #{cm.id}"
      cm.update_attribute(:name, cm.name)
    end
  end

  def self.outlook_header
    ["Title", "First Name", "Middle Name", "Last Name", "Suffix", "Company", "Department", "Job Title", "Business Street", "Business Street 2", "Business Street 3", "Business City", "Business State", "Business Postal Code", "Business Country/Region", "Home Street", "Home Street 2", "Home Street 3", "Home City", "Home State", "Home Postal Code", "Home Country/Region", "Other Street", "Other Street 2", "Other Street 3", "Other City", "Other State", "Other Postal Code", "Other Country/Region", "Assistant's Phone", "Business Fax", "Business Phone", "Business Phone 2", "Callback", "Car Phone", "Company Main Phone", "Home Fax", "Home Phone", "Home Phone 2", "ISDN", "Mobile Phone", "Other Fax", "Other Phone", "Pager", "Primary Phone", "Radio Phone", "TTY/TDD Phone", "Telex", "Account", "Anniversary", "Assistant's Name", "Billing Information", "Birthday", "Business Address PO Box", "Categories", "Children", "Directory Server", "E-mail Address", "E-mail Type", "E-mail Display Name", "E-mail 2 Address", "E-mail 2 Type", "E-mail 2 Display Name", "E-mail 3 Address", "E-mail 3 Type", "E-mail 3 Display Name", "Gender", "Government ID Number", "Hobby", "Home Address PO Box", "Initials", "Internet Free Busy", "Keywords", "Language", "Location", "Manager's Name", "Mileage", "Notes", "Office Location", "Organizational ID Number", "Other Address PO Box", "Priority", "Private", "Profession", "Referred By", "Sensitivity", "Spouse", "User 1", "User 2", "User 3", "User 4", "Web Page"]
  end

  def outlook_row
    emails = self.emails
    email1 = emails[0]
    email2 = emails[1]
    email3 = emails[2]
    ["", "#{first_name}", "#{middel_name}", "#{last_name}", "", "#{company.name if company}", "", "#{title}", "#{company.street1 if company}", "#{company.street2 if company}", "", "#{company.city if company}", "#{company.state if company}", "#{company.zip if company}", "#{company.country if company}", "#{street1}", "#{street2}", "", "#{city}", "#{state}", "#{zip}", "#{country}", "", "", "", "", "", "", "", "", "#{company.fax if company}", "#{company.phone1 if company}", "#{company.phone2 if company}", "", "", "#{company.phone1 if company}", "", "#{phone}", "", "", "#{mobile_phone}", "", "", "", "#{phone}", "", "", "", "", "", "", "", "", "", "", "", "", "#{email1}", "", "", "#{email2}", "", "", "#{email3}", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "#{company.url if company}"]
  end

  def get_prospect_priority current_user_id
    if current_user_id == self.user_id and self.fm_rm_priority #then it is a normal prospect
      return self.fm_rm_priority
    else #it is a shared prospect
      shared_contact_prospect = SharedContactProspectPriority.find_by_user_id_and_contact_id(current_user_id, self.id)
      unless shared_contact_prospect == nil
        return shared_contact_prospect.priority
      else
        return Constants::PROSPECT_PRIORITY::HIGH
      end
    end

    return nil #default
  end

  def self.update_prospect_priority cache_name, prospect_id, priority
    sql = "update #{cache_name} set priority = #{priority} where prospect_id = #{prospect_id}"
    begin
      connection.execute sql
    rescue
      puts "#{sql} failed. But don't worry, it was just the cache."
    end
  end

  def set_prospect_priority(current_user_id, priority)
    if current_user_id == self.user_id #then it is a normal prospect
      self.update_attribute(:fm_rm_priority, priority)
    else #it is a shared prospect
      found = SharedContactProspectPriority.find_by_user_id_and_contact_id(current_user_id, self.id)
      if found
        found.update_attribute(:priority, priority)
      else
        SharedContactProspectPriority.create(:user_id => current_user_id, :contact_id => self.id, :priority => priority)
      end
    end
  end

  def first_name_or_email
    if self.first_name == nil or self.first_name.strip.blank?
      return self.email()
    else
      return self.first_name
    end
  end

  def self.connector_type(share, top_connector)
    #Shared contact are also supposed to be top connectors.
    if top_connector
      if share and share.status_code
        if share.status_code.blank?
          CONNECTOR_TYPE::Top_Connector
        elsif share.status_code == Constants::SHARE_STATUS_CODE::ACCEPTED
          CONNECTOR_TYPE::Shared_Connector
        else
          CONNECTOR_TYPE::Top_Connector
        end
      else
        CONNECTOR_TYPE::Top_Connector
      end
    else
      CONNECTOR_TYPE::Regular
    end
  end

  def destroy_shares()
    #Destroy all related shares when a contact is destroyed
    candidate_shares = Share.find_all_by_contact_id self.id
    candidate_shares.each do |candidate_share|
      related_shares = Share.find_all_by_salt_hash candidate_share.salt_hash
      transaction do
        related_shares.each do |found_share|
          found_share.destroy
        end
      end
    end
  end

  def share
    Share.find_by_contact_id self.id
  end

  def self.find_hops_from_prospect prospect, current_user_id
    contacts = []
    cps = ContactProspect.find(:all, :joins => :prospect, :conditions => ["user_id = ? AND prospect_id = ?", current_user_id, prospect.id])
    if cps
      contacts = cps.collect { |cp| cp.contact_id }
    end
    return contacts
  end

  def self.find_shared_hops_from_prospect prospect, current_user_id
    contacts = []
    share = Share.find_by_user_id_and_sharer_id(current_user_id, prospect.user_id)
    if share
      contacts << share.contact_id
    end
    return contacts
  end

  def self.is_shared_connector hop, current_user_id
    share = Share.find_by_user_id_and_contact_id(current_user_id, hop)
    if share
      return true
    else
      return false
    end
  end

  #def set_company(company_name)
  #  if self.valid?
  #    unless company_name.nil?
  #      company_name = company_name.strip
  #      unless company_name.blank?
  #        company = Company.find_or_create_by_name company_name
  #        self.company_id = company.id
  #        self.company_name = company.name
  #      end
  #    end
  #  end
  #end

  def update_company company_name
    if self.valid?
      unless company_name.nil?
        company_name = company_name.strip
        if company_name.blank?
          self.company_id = 0
          self.company_name = ''
        else
          company = Company.find_or_create_by_name company_name
          unless company.id == self.company_id
            self.company_id = company.id
            self.company_name = company.name
          end
        end
      end
    end
  end

  # Save titles for contact
  def save_contact_titles(positions)
    title_str= ''

    positions.each_with_index do |position, index|
      if position.is_current == 'true'
        company = Company.find_or_create_by_name(position.company.name)
        title = self.titles.build(:position => position.title, :company_id => company.id)
        title_str += ', ' unless index == 0
        title_str += "#{title.position} at #{company.name}"
      end
    end

    self.update_attribute(:title, title_str)
  end

  private
  def create_connections
    Connection.on_new_contact(self)
  end

  def update_connections
    Connection.on_contact_update(self)
  end

  def destroy_connections
    self_id = self.id
    Connection.destroy_all("contact_id = #{self_id} or hop_id = #{self_id}")
    return
  end
end

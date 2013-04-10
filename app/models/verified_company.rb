require 'company_lookup_signature'

class VerifiedCompany < ActiveRecord::Base
  validates :name ,:presence => true
  validates :name , :uniqueness => true
  before_save :add_or_update_lookup_signature
  after_create :create_company_links
  after_save :update_company_display_name
  has_many :companies
  has_one :domain

  def create_company_links
    Company.update_all ["verified_company_id = ?, display_name=?", self.id, self.name], company_lookup_condition
  end

  def company_lookup_condition
    condition = SmartTuple.new(" OR ")
    condition << {:lookup_signature => self.lookup_signature}
    condition << {:domain_id => self.domain_id} unless self.domain_id.nil?
    condition.compile
  end

  private
  def add_or_update_lookup_signature
    self.lookup_signature = self.name.company_lookup_signature
  end

  def update_company_display_name
    Company.update_all({:display_name => self.name}, ["verified_company_id = ?", self.id]) if self.name_changed?
  end
end

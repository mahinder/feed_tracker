class Person < ActiveRecord::Base
  belongs_to :current_company,:class_name=> "Company", :foreign_key=>"current_company_id"
  belongs_to :previous_company,:class_name=> "Company", :foreign_key=>"last_company_id"
  belongs_to :current_designation,:class_name=> "Designation", :foreign_key=>"current_designation_id"
  belongs_to :previous_designation,:class_name=> "Designation", :foreign_key=>"last_designation_id"
  
  def full_name
    "#{self.first_name} #{self.last_name}".titlecase
  end
  
  def previous_company_name
    self.previous_company ? self.previous_company.name : ''
  end
  
  def previous_company_name=(previous_company_name)
    previous_company_name = previous_company_name.strip
    if previous_company_name.blank?
      unless self.last_company_id.nil?
        self.last_company_id = nil
      end
    else
      company = Company.find_or_create_by_name previous_company_name, :select=>"id"
      self.last_company_id = company.id
    end
  end
  
  def current_company_name=(current_company_name)
    current_company_name = current_company_name.strip
    if current_company_name.blank?
      unless self.current_company_id.nil?
        self.current_company_id = nil
      end
    else
      company = Company.find_or_create_by_name current_company_name, :select=>"id"
      self.current_company_id = company.id
    end
  end
  
  def current_company_name
    self.current_company ? self.current_company.name : ''
  end
  
  def current_designation_title=(current_designation_title)
    current_designation_title = current_designation_title.strip
    if current_designation_title.blank?
      unless self.current_designation_id.nil?
        self.current_designation_id = nil
      end
    else
      designation = Designation.find_or_create_by_name current_designation_title, :select=>"id"
      self.current_designation_id = designation.id
    end
  end
  
  def current_designation_title
    self.current_designation ? self.current_designation.name : ''
  end
  
  def previous_designation_title=(previous_designation_title)
    previous_designation_title = previous_designation_title.strip
    if previous_designation_title.blank?
      unless self.last_designation_id.nil?
        self.last_designation_id = nil
      end
    else
      designation = Designation.find_or_create_by_name previous_designation_title, :select=>"id"
      self.last_designation_id = designation.id
    end
  end
  
  def previous_designation_title
    self.previous_designation ? self.previous_designation.name : ''
  end
end

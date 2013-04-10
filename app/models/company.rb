require 'company_lookup_signature'
# Company class has code that relates to 'companies' table.
class Company < ActiveRecord::Base
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
end

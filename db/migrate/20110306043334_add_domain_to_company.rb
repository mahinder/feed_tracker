class AddDomainToCompany < ActiveRecord::Migration
  def self.up
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
            if domain == nil
              domain = Domain.create(:name => domain_name )
            end
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
  end

  def self.down
    remove_column :company, :domain_id
  end
end

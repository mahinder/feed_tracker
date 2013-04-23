class PeopleInNews < ActiveRecord::Base
  validates :person_id, :uniqueness => {:scope => :news_id}
  belongs_to :person
  attr_accessible :news_id , :person_id
  def self.tag_person_in_news news, first_name,last_name,from_company, to_company
    begin
      if from_company.nil? == false
        person = Person.find_or_create_by_first_name_and_last_name_and_current_company_id(
          :first_name=>first_name.strip,
          :last_name=>last_name.strip,
          :current_company_id=>from_company.id)
      elsif to_company.nil? == false
        person = Person.find_or_create_by_first_name_and_last_name_and_current_company_id(
          :first_name=>first_name.strip,
          :last_name=>last_name.strip,
          :current_company_id=>to_company.id)
      else
        person = Person.find_or_create_by_first_name_and_last_name :first_name => first_name, :last_name => last_name
      end
      person.current_company = to_company
      person.previous_company = from_company
      if person.save
        news.people_in_news.create :person_id=>person.id
      end
    rescue
      #Expected a certain pattern
    end
  end
end
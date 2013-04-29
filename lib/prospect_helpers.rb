# To change this template, choose Tools | Templates
# and open the template in the editor.

module ProspectHelpers
  module AllProspects
    def connection_fields(partial_data = false)
      select_query = "connections.id,
                      connections.hop_id,
                      connections.contact_id,
                      connections.share_id,
                      connections.hop_email,
                      contacts.first_name as contact_first_name,
                      contacts.middel_name as contact_middle_name,
                      contacts.last_name as contact_last_name,
                      contacts.title as contact_title,
                      titles.position as contact_partial_title,
                      contacts.display_pic as contact_display_pic,
                      contacts.email as contact_email,
                      hops.first_name as hop_first_name,
                      hops.middel_name as hop_middle_name,
                      hops.last_name as hop_last_name,
                      hops.title as hop_title,
                      hops.display_pic as hop_display_pic"

      select_query << ",`connections`.sor_at,
                        `connections`.intro_at,
                        `connections`.priority,
                        `connections`.is_3rd_hop,
                        `hops`.`user_id` as hop_user_id,
                        `hops`.`street1` as hop_street1,
                        `hops`.`street2` as hop_street2,
                        `hops`.`city` as hop_city,
                        `hops`.`state` as hop_state,
                        `hops`.`country` as hop_country,
                        `hops`.`is_top_connector` as hop_is_top_connector,
                        `companies`.id as company_id,
                        `companies`.name as company_name,
                        `companies`.employees as company_employees,
                        `companies`.location as company_location,
                        `companies`.street1 as company_street1,
                        `companies`.street2 as company_street2,
                        `companies`.city as company_city,
                        `companies`.state as company_state,
                        `companies`.country as company_country,
                        `companies`.zip as company_zip,
                        `companies`.phone1 as company_phone1,
                        `companies`.phone2 as company_phone2,
                        `companies`.url as company_url,
                        `companies`.ticker as company_ticker,
                        `companies`.industry as company_industry,
                        `companies`.revenue as company_revenue,
                        `companies`.domain_id as company_domain_id" unless partial_data

      select_query
    end

    def connection_joins
      "LEFT join contacts contacts on connections.contact_id = contacts.id
       LEFT join contacts hops on connections.hop_id = hops.id
       LEFT join titles titles on contacts.id = titles.contact_id
       LEFT join companies companies on titles.company_id = companies.id"
    end

    def conditions(user, query = nil, query_default_text = nil, target_companies_limit = nil)
      search_param = built_search_params(query, query_default_text)

      if search_param.blank?
        target_companies = user.target_companies.find(:all, :limit => target_companies_limit)
        target_companies_ids = []

        target_companies.each do |tc|
          target_companies_ids += tc.company.matching_company_ids
        end

        ["(`connections`.hop_id is not null AND `connections`.share_id is null) OR ( `companies`.id in (?) )", target_companies_ids]
      else
        "#{search_param} "
      end
    end

    # Methods for internal use of this file
    def built_search_params(query, query_default_text, contacts_only = nil)
      search_param = ''

      if query && !query.strip.blank? && query.strip != query_default_text
        keywords = query.downcase
        keywords = keywords.split(' ').compact
        keywords.map! { |k| k.strip.gsub("'", "''") }
        search_param = keywords.map { |k|
          filtered_search_params(k, contacts_only)
        }.join(' AND ')
      end

      search_param
    end

    def filtered_search_params(k, contacts_only)
      search_query = "contacts.first_name LIKE '%%#{k}%%'
                      OR contacts.last_name LIKE '%%#{k}%%'
                      OR contacts.all_emails LIKE '%%#{k}%%'
                      OR companies.name LIKE '%%#{k}%%'
                      OR contacts.title LIKE '%%#{k}%%'
                      OR contacts.street1 LIKE '%%#{k}%%'
                      OR contacts.street2 LIKE '%%#{k}%%'
                      OR contacts.city LIKE '%%#{k}%%'
                      OR contacts.state LIKE '%%#{k}%%'
                      OR contacts.country LIKE '%%#{k}%%'"

      unless contacts_only
        search_query << "OR hops.first_name LIKE '%%#{k}%%'
                          OR hops.last_name LIKE '%%#{k}%%'
                          OR hops.all_emails LIKE '%%#{k}%%'
                          OR hops.company_name LIKE '%%#{k}%%'
                          OR hops.title LIKE '%%#{k}%%'
                          OR hops.street1 LIKE '%%#{k}%%'
                          OR hops.street2 LIKE '%%#{k}%%'
                          OR hops.city LIKE '%%#{k}%%'
                          OR hops.state LIKE '%%#{k}%%'
                          OR hops.country LIKE '%%#{k}%%'
                          OR companies.url LIKE '#{k}%%'
                          OR companies.url LIKE '%%.#{k}%%'"
      end
      "(" + search_query + ")"
    end
  end

  module ProspectsByHop
    include AllProspects

    def conditions(hop_id, query = nil, query_default_text = nil)
      search_param = built_search_params(query, query_default_text, true)

      if search_param.blank?
        ["connections.hop_id = ? AND `contacts`.`first_name` <> '' and `contacts`.`last_name` <> ''", hop_id]
      else
        ["connections.hop_id = ? AND `contacts`.`first_name` <> '' and `contacts`.`last_name` <> '' AND #{search_param}", hop_id]
      end
    end
  end

  module ProspectsByCompany
    include AllProspects

    def conditions(company, query = nil, query_default_text = nil)
      search_params = built_search_params(query, query_default_text)

      if search_params.blank?
        ["companies.id in (?)", company.matching_company_ids]
      else
        ["companies.id in (?) AND #{search_params}", company.matching_company_ids]
      end
    end
  end
end
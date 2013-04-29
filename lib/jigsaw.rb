require 'net/http'
require 'net/https'
require 'uri'
require 'json'

module Jigsaw
  class JCompany
    include Constants
    attr_accessor :token, :baseurl, :res_format, :company_domain_not_available_at_jigsaw

    def initialize(token = nil, baseurl = "www.jigsaw.com", res_format = "json")
      @token = token
      @baseurl = baseurl
      @res_format = res_format
      @company_domain_not_available_at_jigsaw = []
    end

    def search_company(name)
      #puts "<><><><Searching For: #{name}"
      method = '/rest/searchCompany' + '.' + self.res_format
      token_str = "?token=#{self.token}"
      q = "&name=#{name}"
      if name and name.strip != ""
        path = method + token_str + q
        http = Net::HTTP.new(self.baseurl, 443)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        resp, data = http.get(path)
        case resp
        when Net::HTTPSuccess
          jp = JSON.parse(data)
        else
          jp = nil
        end
        return jp
      else
        return nil
      end
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
        Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      puts e.message
      puts e.backtrace
    end

    def get_company(company_id)
      method = "/rest/companies/#{company_id}" + "." + self.res_format
      token = "?token=#{self.token}"
      if company_id and company_id.to_s.strip != ""
        path = method + token
        http = Net::HTTP.new(self.baseurl, 443)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        resp, data = http.get(path)
        case resp
        when Net::HTTPSuccess
          jp = JSON.parse(data)
        else
          jp = nil
        end
        return jp
      else
        return nil
      end
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
        Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      puts e.message
      puts e.backtrace
    end

    def process_company_response(input_url, company_row)
      h = {}
      company = {}
      company_row.each{|k,v| company.merge!({k => v.to_s.strip})}
      if input_url.strip == company["website"]
        h.merge!({:street1 => company["address"]}) unless company["address"].empty?
        h.merge!({:city => company["city"]}) unless company["city"].empty?
        h.merge!({:state => company["state"]}) unless company["state"].empty?
        h.merge!({:zip => company["zip"]}) unless company["zip"].empty?
        h.merge!({:country => company["country"]}) unless company["country"].empty?
        h.merge!({:phone1 => company["phone"]}) unless company["phone"].empty?

        h.merge!({:industry => company["industry1"]}) unless company["industry1"].empty?
        h.merge!({:industry2 => company["industry2"]})  unless company["industry2"].empty?
        h.merge!({:industry3 => company["industry3"]}) unless company["industry3"].empty?

        h.merge!({:sub_industry => company["subIndustry1"]}) unless company["subIndustry1"].empty?
        h.merge!({:sub_industry2 => company["subIndustry2"]}) unless company["subIndustry2"].empty?
        h.merge!({:sub_industry3 => company["subIndustry3"]}) unless company["subIndustry3"].empty?

        h.merge!({:employees => company["employeeCount"]}) unless company["employeeCount"].empty?
        h.merge!({:employee_range => company["employeeRange"]}) unless company["employeeRange"].empty?

        h.merge!({:revenue => company["revenue"]}) unless company["revenue"].empty?
        h.merge!({:revenue_range => company["revenueRange"]}) unless company["revenueRange"].empty?

        h.merge!({:stock_symbol => company["stockSymbol"]}) unless company["stockSymbol"].empty?
        h.merge!({:stock_exchange => company["stockExchange"]}) unless company["stockExchange"].empty?
        h.merge!({:sic_code => company["sicCode"]}) unless company["sicCode"].empty?
        h.merge!({:active_contacts => company["activeContacts"]}) unless company["activeContacts"].empty?
        h.merge!({:ownership => company["ownership"]}) unless company["ownership"].empty?
      end
      return h
    end

    def get_jdata(company_url)
      company_data = nil
      domain_name = HttpHelper.get_domain(company_url)
      domain = Domain.find_or_create_by_name(domain_name)
      domain_id = domain.id

      if @company_domain_not_available_at_jigsaw.include?(domain_id)
        #puts "Skipped: #{company_url} - Earlier found that info not available at jigsaw"
        return nil
      end

      company_template = CompanyTemplate.find_by_domain_id(domain_id)
      if company_template.nil?
        result_from_url = search_company(company_url)
        #puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        #puts result_from_url.inspect
        if result_from_url && result_from_url["companies"] && result_from_url["companies"][0]
          company_jigsaw_id = result_from_url["companies"][0]["companyId"]
          if company_jigsaw_id
            result = get_company(company_jigsaw_id)
            if result
              found_company = result["companies"][0]
              company_data = process_company_response(company_url, found_company)
              template = CompanyTemplate.new(company_data)
              template.name = found_company["name"]
              template.domain_id = domain_id
              template.save
            end
          end
        else
          #puts "#{company_url} - Info not available at jigsaw"
          @company_domain_not_available_at_jigsaw << domain_id
        end
        return company_data
      else
        #puts "Found #{company_url} in company templates"
        company_data = company_template.attributes
        #Currently we don't have intentions of using the following but we plan to use them in future.
        company_data.delete("name")
        company_data.delete("domain_id")
        return company_data
      end
    rescue Errno::ETIMEDOUT
      #puts "Exception: Connection had timed out while searching for #{company_url}."
    end

    def append_companies_by_id(jigsaw_candidates)
      if jigsaw_candidates && !jigsaw_candidates.empty?
        candidate_companies = Company.find(:all, :conditions => ["id IN ( #{jigsaw_candidates} )"])
        if candidate_companies && !candidate_companies.empty?
          candidate_companies.each do |com|
            if !com.url.blank?
              raw_url = com.url
              format_url = raw_url.match(/^http|https\:\/\//) ? raw_url.gsub(/(http|https)\:\/\//,'').gsub(/\/.*/,'') : raw_url
              format_url = format_url.match(/^www./) ? format_url : 'www.'.concat(format_url)
              append_attr_hash = get_jdata(format_url)
              if append_attr_hash
                com.append_jsw_data(append_attr_hash)
              end
            end
          end
        end
      end
    end

    def append_company_by_id(jigsaw_candidate)
      if jigsaw_candidate
        candidate_company = Company.find(:first, :conditions => ["id = #{jigsaw_candidate}"])
        if candidate_company
          if !candidate_company.url.blank?
            raw_url = candidate_company.url
            format_url = raw_url.match(/^http|https\:\/\//) ? raw_url.gsub(/(http|https)\:\/\//,'').gsub(/\/.*/,'') : raw_url
            format_url = format_url.match(/^www./) ? format_url : 'www.'.concat(format_url)
            append_attr_hash = get_jdata(format_url)
            if append_attr_hash
              append_attr_hash.merge!({:jigsaw_flagged => true})
              candidate_company.append_jsw_data(append_attr_hash)
            end
          end
        end
      end
    end
  end
end


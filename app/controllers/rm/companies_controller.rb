require 'csv'
require 'jigsaw'
require 'prospect_helpers'
require 'company_lookup_signature'

class Rm::CompaniesController < ApplicationController
  include ProspectHelpers::ProspectsByCompany
  include ApplicationHelper
  include Salesforce

  before_filter :init_days_ago_filter, :only => :show_ajax

  def list
  
    name = params[:term]
    unless name.nil? or name.blank? or code_injection? name
      @companies = VerifiedCompany.find(:all, :select => "name", :conditions => ['name LIKE ?', "#{name}%"], :limit => 10, :order => "name")
    else
      @companies = []
    end
    @companies = @companies.map(&:name)
    respond_to do |format|
      format.json { render :json => @companies.to_json }
    end
  end

  def show_ajax
    @company = Company.find(params[:id])
    session[:redirect_path] = "#{get_target_companies_main_path}?days_ago=#{@number_of_days}"
    @sf_link_function = generate_sf_link(current_user)

    if @company
      render :update do |page|
       @connections_limit = 2
        news = @company.news(current_user, @number_of_days.days.ago)

        page.hide 'loading-news-tc'
        if news.present? || URI(request.referer).path == "/main/get_target_companies"

          page.insert_html :bottom, 'companies', :partial => 'company', :locals => {:company => @company, :news => news, :sf_link_function => @sf_link_function}
          page << "$('##{companies_news_container_dom_id(@company)}').fadeIn('slow');"
          page.insert_html :bottom, 'target_companies_list', :partial => 'target_company'
          page << "$(window).scroll()"
        end
      end
    else
      raise "Company #{params[:id]} not found"
    end
  end

  def create_target_companies
    success = false
    name = params[:company][:name]

    if name.blank? or code_injection? name
      @message = "Please enter a name."
    else
      tcs = current_user.target_companies
      if tcs.count < current_user.tc_limit
        @company = Company.find_unique name
        target_company = tcs.find_by_company_id @company.id
        if target_company.nil?
          tcs.create(:company_id => @company.id)
          @message = "Added \"#{@company.name}\" to targets."
          success = true
        else
          @message = "\"#{@company.name}\" is already targeted."
        end
      else
        @need_upgrade = true
      end
    end

    render :update do |page|
      page << "$('#upgrade-membership').modal('show');" if @need_upgrade

      if params[:gritter_enabled].present?
        page << "var unique_id =  $.gritter.add({ title: 'Saved Changes',
                  text: '#{@message}',
                  sticky: false,
                  time: '1000'
                  });
               if(unique_id-1 > 0){
                                   $.gritter.remove((unique_id-1), {
                                                fade: true, // optional
                                                speed: 'fast' // optional
                                    });
                          }"
      else
        page.replace 'message_small_green', :partial => '/layouts/message_small_green'
      end
      
      page[:company_name].value = ""
      page[:company_name].select
      
      if success
        page << "addTargetCompany(#{{:id => @company.id, :name => @company.name}.to_json})" if URI(request.referer).path == "/main/get_target_companies"
        page.insert_html :bottom, 'target_companies_list', :partial => 'target_company' if URI(request.referer).path != "/main/get_target_companies"
      end
    end
  end

  def show
    params[:sf] = 'name' unless params[:sf]

    @company = Company.find(params[:id])
    @connections = current_user.connections.paginate(:all,
                                                     :select => connection_fields,
                                                     :joins => connection_joins,
                                                     :conditions => conditions(@company, params[:search], "Search prospect & 1st Hop"),
                                                     :group => "titles.contact_id",
                                                     :order => "hop_id, contact_first_name, contact_last_name",
                                                     :page => params[:page],
                                                     :per_page => 5)

    li_text_url = current_user.get_linkedin_connection_count_with_url @company
    @li_conn_text = li_text_url[:display_text]
    @li_conn_url = li_text_url[:url]
    @li_conn_count = li_text_url[:count]

    respond_to do |format|
      format.html { render }
    end
  end

  def destroy
    target_company = current_user.target_companies.find_by_company_id params[:id]

    respond_to do |format|
      if (target_company.destroy)
        format.json { render :json => true }
      else
        format.json { render :status => :unprocessable_entity, :json => params[:id] }
      end
    end
  end

  def target_companies
    companies = current_user.companies.all :select => "companies.id, companies.name, companies.display_name", :limit => current_user.tc_limit
    respond_to do |format|
      format.json { render :json => companies.collect { |c| {:id => c.id, :name => c.name} }.to_json }
    end
  rescue Exception => e
    respond_to do |format|
      format.json { render :json => e.message, :status => :internal_server_error }
    end
  end

  #AJAX

  def export_prospects
    render :update do |page|
      company = Company.find(params[:company_id], :select => 'name, display_name')
      DataExportJob.create 'user_id' => current_user.id, 'company_id' => params[:company_id], 'type' => Constants::DATA_EXPORT_TYPE::RM_PROSPECTS
      page.replace_html 'message_small_green', :text => "We have emailed you an excel (csv) file showing prospects in #{company.name}."
    end
  end

  private
  def csv_file?(file_to_upload)
    get_file_format(file_to_upload) == 'csv'
  end

  def save_company(data)
    name = data[:company]
    if TargetCompany.create_target_company(current_user, name)
      @companies << name
      @count += 1
    end
  end

end

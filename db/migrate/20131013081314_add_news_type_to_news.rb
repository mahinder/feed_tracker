class AddNewsTypeToNews < ActiveRecord::Migration
  def self.up
    add_column :news, :news_type_id, :integer
    news = News.find :all,:select=>"DISTINCT reason"
    news.each do |news_item|
      reason = news_item.reason
      type = nil
      case reason
      when 'Recent Funding','Recently funded',' Venture Funded','Venture Funded','Financing'
        type = NewsType.find_by_name 'Recently funded'
      else
        type = NewsType.find_by_name reason
      end
      News.update_all "news_type_id = #{type.id}","reason = '#{reason}'" unless type.nil?
    end
  end

  def self.down
    remove_column :news, :news_type_id
  end
end

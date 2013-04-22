module Admin::NewsHelper
  def bg_style(news)
    if news.blocked
      'background-color: lightgray;'
    elsif news.ready
      'background-color: #87D48D;'
    else
      'background-color: #FFFDA2;'
    end
  end

  def processing?(news_id)
#    !!RunningJob.find_by_resource_id_and_resource_type(news_id, 1)
  end
end

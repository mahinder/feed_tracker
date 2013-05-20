require 'net/http'
class SendTaggingNews
  def self.send_tagging
  users  = User.includes(:news => [:companies ,:industries,:people]).all
  response = ""
    users.each do |user|
    p  response =  "{" + user.news.to_json(:include => [:companies ,:industries,:people]) + "}"
      uri = URI('http://localhost:4000/mock/user_apis/mock_user_response.json')
      res = Net::HTTP.post_form(uri, {"news" => response})
      puts res.body
  end if users 
    
  end
end

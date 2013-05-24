require 'net/http'
class SendTaggingNews
  def self.send_tagging
#  users  = User.includes(:news => [:companies ,:industries,:people]).all
#  response = ""
#    users.each do |user|
#    p  response =  "{" + user.news.to_json(:include => [:companies ,:industries,:people]) + "}"
#      uri = URI(user.end_point)
#      res = Net::HTTP.post_form(uri, {"news" => response})
#      puts res.body
#  end if users 
#
#http = Net::HTTP.new('http://www.spoke.com')
#response = http.request_put('/?access_token=123', jsonbody)
 uri = URI('http://www.spoke.com/api/v1/search.json?q=google&type=company&auth_token=DysxWWl557Xp26U8yyNt&page_len=1')
 res = Net::HTTP.get(uri)
 json_resp =  JSON.parse(res) if res
 company_id = resp["results"][0]["id"]  if json_resp
 http = Net::HTTP.new('http://www.spoke.com')
 jsonbody = JSON.parse(tags: ["searchaaaa"])
 response = http.request_put('/api/v1/companies/3e122f809e597c1003565d3f.json?auth_token=DysxWWl557Xp26U8yyNt', jsonbody)
 
 

 
    
  end
end

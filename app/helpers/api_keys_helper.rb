module ApiKeysHelper
  
  def key_exists key
   current_user.api_key ? current_user.api_key.send(key) : ""
  end
end

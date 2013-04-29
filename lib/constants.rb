# This Module defines the various contants that are used across the Application
module Constants
  class Enum
    def self.add(key,value)
      @hash ||= {}
      @hash[key]=value
    end

    def self.const_missing(key)
      @hash[key]
    end

    def self.each
      @hash.each {|key,value| yield(key,value)}
    end

    def self.name(value)
      @hash.invert[value]
    end
  end

  class SOCIAL_IMPORT < Enum
    self.add :FACEBOOK, 0
    self.add :LINKEDIN, 1
  end

  class NETMAIL_IMPORT < Enum
    self.add :GMAIL, 0
    self.add :YAHOO, 1
    self.add :OUTLOOK, 2
    self.add :HOTMAIL, 3
  end  
  
  class FILE_UPLOAD < Enum
    self.add :CONSTCSV, 0
    self.add :PDF, 1
    self.add :BCARD, 2
    self.add :OTHER, 3
    
  end  
  
  class FILTER_FIELDS < Enum
    self.add :SOURCE, 0
    self.add :FACEBOOK_STATUS, 1
    self.add :LINKEDIN_STATUS, 2
    self.add :SUSPENDED,3
  end  

  class PLANS < Enum
    self.add :FREE,0
    self.add :BASIC,1
    self.add :PREMIUM, 2
  end

  class CONTACT_TYPE < Enum
    self.add :CONTACT,1
    self.add :PROSPECT,2
    #Prospect turns into a Direct Contact.A “person” can be a 2nd hop and a 1st hop (i.e. “contact”) at the same time
    self.add :SHARED,3
  end

  class TOP_CONNECTOR_STATUS < Enum
    self.add :NotStarted, 1
    self.add :InProcess, 2
    self.add :Completed,3
  end

  class PROSPECT_PRIORITY < Enum
    self.add :LOW, 1
    self.add :MEDIUM, 2
    self.add :HIGH, 3
  end

  class TEMPLATE_TYPE < Enum
    self.add :SOR, 0
    self.add :INTRO, 1
  end

  class TC_NETWORK_STATUS < Enum
    self.add :NONE, 0
    self.add :CLOSE, -1
    self.add :OPEN, -2
  end
  
  class RM_COMPANY_STATUS < Enum
    self.add :NotStarted, 1
    self.add :InProcess, 2
    self.add :Completed,3
  end

  class CONNECTOR_TYPE < Enum
    self.add :Top_Connector, 1
    self.add :Shared_Connector, 2
    self.add :Regular, 3
  end

  class AUTH_PROVIDER < Enum
    self.add :LINKEDIN, 1
  end

  class AUTHENTICATION_TYPE < Enum
    self.add :OAUTH, 1
  end
  
  class CONNECTIONS_COUNT_SOURCE < Enum
    self.add :LINKEDIN, 1
  end
  
  class ERRORS < Enum
    self.add :LINKEDIN_THROTTLE_LIMIT, 1
  end
  
  class LINKEDIN_API_CALL_TYPE < Enum
    self.add :PEOPLE_SEARCH, 1
  end
  
  class THIRD_PARTY_API_PROVIDER < Enum
    self.add :LINKEDIN, 1
  end
  
  class INTEREST_CACHE_UPDATE_REASON < Enum
    self.add :REFRESH_FOR_USER, 1
    self.add :NEW_NEWS, 2
    self.add :DELETE_CONNECTIONS, 3
    self.add :NEWS_UPDATE, 4
    self.add :NEWS_CREATE, 5
  end
  
  class CONNECTIONS_TYPE_IN_NEWS < Enum
    self.add :NONE, 0
    self.add :PSN, 1
    self.add :LINKEDIN, 2
    self.add :PSN_LINKEDIN, 3
  end

  class SHARE_STATUS_CODE < Enum
    self.add :ACCEPTED, 10
    self.add :PENDING, 9
    self.add :REQUESTED, 8
  end
  
  class DATA_EXPORT_TYPE < Enum
    self.add :PROSPECTS, 1
    self.add :RM_PROSPECTS, 2
  end

  class RUNNING_JOBS <Enum
    self.add :NEWS, 1
    self.add :FACEBOOK, 2
    self.add :GOOGLE, 3
    self.add :LINKEDIN, 4
    self.add :YAHOO, 5
  end
end

require 'consistent_company'
class String
  def company_lookup_signature
    #remove extra info eg.
    #All Covered, a division of Konica Minolta Business Solutions U.S.A., Inc.
    #Kazeon Systems | EMC
    #PepsiCo - Chicago
    self.gsub(/(,| - | -- |\/| \| ).*/, ' ').company_namer
  end
end
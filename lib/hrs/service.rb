require "hrs"
require "rails"
require "savon"

module HRS
  class Service < Rails::Engine
    include ActionView::Helpers::TagHelper
  
    TestServer = "http://iut-service.hrs.com:8080"
    ProductionServer = "http://p-service.hrs.com:8080"
    Settings = open("config/hrs_service.yml") {|f| YAML.load(f) }
    
    attr_accessor :client
    attr_accessor :environment
    attr_accessor :version
    attr_accessor :iso3language
    
    #hrs = HRS::Service.new
    
    def initialize(args={})
      self.environment = args[:env] || ::Rails.env
      self.version = args[:version] || Settings["HRSServiceVersion"]
      self.iso3language = args[:language] || Settings["Iso3Language"]
      server_path = "/service/hrs/#{self.version}/HRSService?wsdl"
      self.client = Savon::Client.new do |wsdl, http, wsse|
        case self.environment
        when "production"
          wsdl.document = ProductionServer + server_path
        else
          wsdl.document = TestServer + server_path
        end
      end      
    end
    
    #TODO: Static data in yaml file
    def request(procedure, data_to_send="")
      begin
        result = client.request procedure do |soap, wsdl|        
          client_type = content_tag("clientType", Settings["ClientType"])
          client_key = content_tag("clientKey", Settings["ClientKey"])
          client_password = content_tag("clientPassword", Settings["ClientPassword"])
          
          language = content_tag("language", content_tag("iso3Language", iso3language))
          iso3Country = content_tag("iso3Country", Settings["Iso3Country"])
          isoCurrency = content_tag("isoCurrency", Settings["IsoCurrency"])
          
          credentials = content_tag("credentials", client_type + client_key + client_password)
          locale = content_tag("locale", language + iso3Country + isoCurrency)
          
          procedure_request = "<#{procedure}Request xmlns=''>#{credentials}#{locale}#{data_to_send}</#{procedure}Request>"
          soap_xml = "<soap:Body><#{procedure} xmlns='com.hrs.soap.hrs'>#{procedure_request}</#{procedure}></soap:Body>"
          soap.xml = "<soap:Envelope xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'>#{soap_xml}</soap:Envelope>"
        end
      rescue
        nil
      end
    end
    
    
    def ping
      begin
        data = content_tag("echoData", "I am alive")
        request("ping", data).to_hash[:ping_response][:ping_response]
      rescue
        false
      end
    end
    
    
    def search_locations(city)
      begin
        data = "<fuzzySearch xmlns:xsi='...' xsi:nil='true' />"
        data += content_tag("locationName", city)
        data += content_tag("locationLanguage", content_tag("iso3Language", iso3language))
        request("locationSearch", data).to_hash[:location_search_response][:location_search_response][:locations]
      rescue
        {}
      end
    end
    
    #Default location_id for Berlin = 55133
    def search_hotels(location_id)
      begin
        locationCriterion = "<fuzzySearch xmlns:xsi='...' xsi:nil='true' />"
        locationCriterion += content_tag("locationID", location_id)
        locationCriterion += content_tag("perimeter", 1000)
        
        searchCriterion = content_tag("locationCriterion", locationCriterion) 
        searchCriterion += content_tag("hotelNames", "")
        searchCriterion += content_tag("minCategory", "0")
        searchCriterion += content_tag("minAverageRating", "0")
        searchCriterion += content_tag("maxResults", "0")
        data = content_tag("searchCriterion", searchCriterion )
        request("hotelSearch", data)
      rescue
        {}
      end
    end
    
  end
end
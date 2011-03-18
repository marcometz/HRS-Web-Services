require "hrs"
require "rails"
require "savon"

module HRS
  class Service < Rails::Engine
    include ActionView::Helpers::TagHelper
  
    HRSServiceVersion = "015"
    TestServer = "http://iut-service.hrs.com:8080"
    ProductionServer = "http://p-service.hrs.com:8080"
    Iso3Language = "ENG"
    
    attr_accessor :client
    attr_accessor :environment
    attr_accessor :version
    
    #hrs = HRS::Service.new
    
    def initialize(args={})
      self.environment = args[:env] || ::Rails.env
      self.version = args[:version] || HRSServiceVersion
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
      result = client.request procedure do |soap, wsdl|        
        client_type = content_tag("clientType", "317")
        client_key = content_tag("clientKey", "424316692")
        client_password = content_tag("clientPassword", "hf8t2!$3fg")
        
        language = content_tag("language", content_tag("iso3Language", Iso3Language))
        iso3Country = content_tag("iso3Country", "DEU")
        isoCurrency = content_tag("isoCurrency", "EUR")
        
        credentials = content_tag("credentials", client_type + client_key + client_password)
        locale = content_tag("locale", language + iso3Country + isoCurrency)
        
        procedure_request = "<#{procedure}Request xmlns=''>#{credentials}#{locale}#{data_to_send}</#{procedure}Request>"
        soap_xml = "<soap:Body><#{procedure} xmlns='com.hrs.soap.hrs'>#{procedure_request}</#{procedure}></soap:Body>"
        soap.xml = "<soap:Envelope xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'>#{soap_xml}</soap:Envelope>"
      end
    end
    
    
    def ping
      data = content_tag("echoData", "Are you alive")
      request("ping", data)
    end
    
    
    def search_locations(city)
      data = "<fuzzySearch xmlns:xsi='...' xsi:nil='true' />"
      data += content_tag("locationName", city)
      data += content_tag("locationLanguage", content_tag("iso3Language", Iso3Language))
      request("locationSearch", data)
    end
    
    
  end
end
require "hrs"
require "rails"
require "savon"

module HRS
  class Service < Rails::Engine
      
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
          client_type = ct("clientType", Settings["ClientType"])
          client_key = ct("clientKey", Settings["ClientKey"])
          client_password = ct("clientPassword", Settings["ClientPassword"])
          
          language = ct("language", ct("iso3Language", iso3language))
          iso3Country = ct("iso3Country", Settings["Iso3Country"])
          isoCurrency = ct("isoCurrency", Settings["IsoCurrency"])
          
          credentials = ct("credentials", client_type + client_key + client_password)
          locale = ct("locale", language + iso3Country + isoCurrency)
          
          procedure_request = "<#{procedure}Request xmlns=''>#{credentials}#{locale}#{data_to_send}</#{procedure}Request>"
          soap_xml = "<soap:Body><#{procedure} xmlns='com.hrs.soap.hrs'>#{procedure_request}</#{procedure}></soap:Body>"
          soap.xml = "<soap:Envelope xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'>#{soap_xml}</soap:Envelope>"
        end
        result.to_hash
      rescue
        nil
      end
    end
    
    
    def ping
      begin
        data = ct("echoData", "I am alive")
        request("ping", data)[:ping_response][:ping_response]
      rescue
        false
      end
    end
    
    
    def search_locations(city)
      begin
        data = "<fuzzySearch xmlns:xsi='...' xsi:nil='true' />"
        data += ct("locationName", city)
        data += ct("locationLanguage", ct("iso3Language", iso3language))
        request("locationSearch", data)[:location_search_response][:location_search_response][:locations]
      rescue
        {}
      end
    end
    
    #Default location_id for Berlin = 55133
    def search_hotels(location_id, perimeter=1000, maxResults=0, minAverageRating=0, minCategory=0)
      begin
        locationCriterion = "<fuzzySearch xmlns:xsi='...' xsi:nil='true' />"
        locationCriterion += ct("locationId", location_id)
        locationCriterion += ct("perimeter", perimeter)
        
        searchCriterion = ct("locationCriterion", locationCriterion) 
        searchCriterion += ct("hotelNames", "")
        searchCriterion += ct("minCategory", minCategory)
        searchCriterion += ct("minAverageRating", minAverageRating)
        searchCriterion += ct("maxResults", maxResults)
        data = ct("searchCriterion", searchCriterion )
        request("hotelSearch", data)
      rescue
        {}
      end
    end

    #Default location_id for Berlin = 55133
    def available_hotels(location_id, from_date, to_date, perimeter=5000, maxResults=0, minCategory=0, roomType="single", adultCount=1, orderKey="price", orderDirection="ascending" )
      begin
        locationCriterion = "<fuzzySearch xmlns:xsi='...' xsi:nil='true' />"
        locationCriterion += ct("locationId", location_id)
        locationCriterion += ct("perimeter", perimeter)
        
        searchCriterion = ct("locationCriterion", locationCriterion) 
        searchCriterion += ct("minCategory", minCategory)
        searchCriterion += ct("maxResults", maxResults)
        
        availC = availCriterion(from_date, to_date, roomType , adultCount )        
        
        orderCriterion = ct("orderKey", orderKey)
        orderCriterion += ct("orderDirection", orderDirection)
        
        data = ct("searchCriterion", searchCriterion ) + ct("availCriterion", availC ) + ct("orderCriterion", orderCriterion ) 
        request("hotelAvail", data)[:hotel_avail_response][:hotel_avail_response][:hotel_avail_hotel_offers]
      rescue
        {}
      end
    end
    
    #Default hotel_key = 24346
    def hotel_availabilty(hotel_key, from_date, to_date, roomType, adultCount)
      begin
        availC = availCriterion(from_date, to_date, roomType , adultCount )        
        data = ct("hotelKeys", hotel_key)
        data += ct("availCriterion", availC)
        
        request("hotelDetailAvail", data)
      rescue
        {}
      end
    end
    



    private
    
      def ct(tag, text)
        "<#{tag}>#{text}</#{tag}>"
      end
      
      def availCriterion(from_date, to_date, roomType="single" , adultCount=1 )
        data = ct("from", from_date )
        data += ct("to", to_date )
        data += "<minPrice xmlns:xsi='...' xsi:nil='true' />"
        data += "<maxPrice xmlns:xsi='...' xsi:nil='true' />"
        data += ct("includeBreakfastPriceToDetermineCheapestOffer", "true")
        data += ct("roomCriteria", ct("id", "1") + ct("roomType", roomType) + ct("adultCount", adultCount))
      end
    
  end
end
require "hrs"
require "rails"
require "savon"

module HRS
  class Service < Rails::Engine
    
    HRSServiceVersion = "014"
    TestServer = "http://iut-service.hrs.com:8080"
    ProductionServer = "http://p-service.hrs.com:8080"
    
    attr_accessor :client
    attr_accessor :environment
    attr_accessor :version
    
    def initialize(args={})
      self.environment = args[:env] || ::Rails.env
      self.version = args[:version] || HRSServiceVersion
      server_path = "/service/hrs/#{self.version}/HRSService?wsdl"
      self.client = Savon::Client.new do |wsdl, http|
        case self.environment
        when "production"
          wsdl.document = ProductionServer + server_path
        else
          wsdl.document = TestServer + server_path
        end
      end      
    end
    
    def ping
      client.request "HRSPingRequest"
    end
    
  end
end
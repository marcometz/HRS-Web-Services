require "hrs"
require "rails"
require "savon"

module Hrs
  class Service < Rails::Engine
    
    TestServer = "http://iut-service.hrs.com:8080/service/hrs/014/HRSService?wsdl"
    ProductionServer = "http://iut-service.hrs.com:8080/service/hrs/014/HRSService?wsdl"
    
    attr_accessor :client
    
    def initialize(args={})
      self.client = Savon::Client.new do |wsdl, http|
        wsdl.document = TestServer
      end      
    end
    
    
    
  end
end
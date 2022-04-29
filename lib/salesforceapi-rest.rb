require "salesforceapi-rest/version"
require "salesforceapi-rest/request"
require "salesforceapi-rest/errors"
require 'net/https'
require 'net/http'
require 'active_resource'
require 'httparty'
require 'builder'
require 'crack/xml'
require 'cgi'

module Salesforceapi
  module Rest
    class Client
      include HTTParty
      extend SalesforceApi::Request

      base_uri "https://na7.salesforce.com"
      default_params :output => 'json'
      format :json
      @@ssl_port = 443



      # set header for httparty
      def self.set_headers (auth_setting)
        headers (auth_setting)
      end

      def initialize(refresh_token, metadata_uri, client_id, client_secret)
        @refresh_token = refresh_token
        @client_id = client_id
        @client_secret = client_secret
        @metadata_uri = metadata_uri
        @api_version = "v54.0"
        @ssl_port = 443  # TODO, right SF use port 443 for all HTTPS traffic.

      end


      def create(object, attributes)
        config_authorization!
        path = "/services/data/#{@api_version}/sobjects/#{object}/"
        target = @instance_uri + path

        self.class.base_uri @instance_uri

        data = ActiveSupport::JSON::encode(attributes)
        resp = SalesforceApi::Request.do_request("POST", target, @auth_header, data)

        # HTTP code 201 means it was successfully saved.
        if resp.code != 201
          message = ActiveSupport::JSON.decode(resp.body)[0]["message"]
          SalesforceApi::Errors::ErrorManager.raise_error("HTTP code " + resp.code.to_s + ": " + message, resp.code)
        else
          return ActiveSupport::JSON.decode(resp.body)
        end

      end

      def describe(object)
        path = "/services/data/#{@api_version}/sobjects/#{object}/describe"
        config_authorization!
        target = @instance_uri + path

        self.class.base_uri @instance_uri

        resp = SalesforceApi::Request.do_request("GET", target, @auth_header, nil)
        if (resp.code != 200) || !resp.success?
          message = ActiveSupport::JSON.decode(resp.body)[0]["message"]
          SalesforceApi::Errors::ErrorManager.raise_error("HTTP code " + resp.code.to_s + ": " + message, resp.code)
        else
          return ActiveSupport::JSON.decode(resp.body)
        end
      end

      def resources
        path = "/services/data/#{@api_version}"
        config_authorization!
        target = @instance_uri + path

        self.class.base_uri @instance_uri

        resp = SalesforceApi::Request.do_request("GET", target, @auth_header, nil)
        if (resp.code != 200) || !resp.success?
          message = ActiveSupport::JSON.decode(resp.body)[0]["message"]
          SalesforceApi::Errors::ErrorManager.raise_error("HTTP code " + resp.code.to_s + ": " + message, resp.code)
        else
          return ActiveSupport::JSON.decode(resp.body)
        end
      end

      def config_authorization!
        @authorization_configured ||= do_config_authorization!
      end

      def do_config_authorization!
        target = CGI::unescape("https://login.salesforce.com/services/oauth2/token?grant_type=refresh_token&client_id=#{@client_id}&client_secret=#{@client_secret}&refresh_token=#{@refresh_token}")
        resp = SalesforceApi::Request.do_request("POST", target, {"content-Type" => 'application/json'}, nil)
        if (resp.code != 200) || !resp.success?
          message = ActiveSupport::JSON.decode(resp.body)["error_description"]
          SalesforceApi::Errors::ErrorManager.raise_error(message, 401)
        else
          response = ActiveSupport::JSON.decode(resp.body)
        end
        @instance_uri = response['instance_url']
        @access_token = response['access_token']
        @auth_header = {
          "Authorization" => "OAuth " + @access_token,
          "content-Type" => 'application/json'
        }
        true
      end


      def add_custom_field(attributes)
        config_authorization!
        auth_header = {
          "Authorization" => "OAuth " + @access_token,
          'Connection' => 'Keep-Alive',
          'Content-Type' => 'text/xml',
          'SOAPAction' => '""'
        }

        self.class.base_uri @metadata_uri

        data = (Envelope % [@access_token, custom_fields_xml(attributes)])
        resp = SalesforceApi::Request.do_request("POST", @metadata_uri, auth_header, data.lstrip)
        xml_response = Crack::XML.parse(resp.body)

        if resp.code != 200
          SalesforceApi::Errors::ErrorManager.raise_error("HTTP code " + resp.code.to_s + " xml response: " + resp.body, resp.code)
        else
          return xml_response
        end
      end


      def custom_fields_xml(opts)
        # Create XML text from the arguments.
        expanded = ''
        @builder = Builder::XmlMarkup.new(:target => expanded)
        @builder.tag! :create, :xmlns => "http://soap.sforce.com/2006/04/metadata" do |b|
          b.tag! :metadata, "xsi:type" => "ns2:CustomField", "xmlns:ns2" => "http://soap.sforce.com/2006/04/metadata" do |c|
            opts.each { |k,v| c.tag! k, v }
          end
        end
        expanded
      end

      Envelope = <<-HERE
      <?xml version="1.0" encoding="utf-8" ?>
      <soapenv:Envelope
         xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
         xmlns:xsd="http://www.w3.org/2001/XMLSchema"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <soapenv:Header>
           <ns1:SessionHeader soapenv:mustUnderstand="0" xsi:type="ns1:SessionHeader"
               xmlns:ns1="http://soap.sforce.com/2006/04/metadata">
              <ns1:sessionId>%s</ns1:sessionId>
           </ns1:SessionHeader>
           <ns2:CallOptions soapenv:mustUnderstand="0" xsi:type="ns2:SessionHeader"
               xmlns:ns2="http://soap.sforce.com/2006/04/metadata">
              <ns2:client>apex_eclipse/16.0.200906151227</ns2:client>
           </ns2:CallOptions>
           <ns3:DebuggingHeader soapenv:mustUnderstand="0" xsi:type="ns3:DebuggingHeader"
               xmlns:ns3="http://soap.sforce.com/2006/04/metadata">
              <ns3:debugLevel xsi:nil="true" />
           </ns3:DebuggingHeader>
        </soapenv:Header>
        <soapenv:Body>
          %s
        </soapenv:Body>
      </soapenv:Envelope>
        HERE

    end
  end
end

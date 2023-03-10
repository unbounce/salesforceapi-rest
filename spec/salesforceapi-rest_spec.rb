require 'spec_helper'
require 'json'

describe Salesforceapi::Rest::Client do

  before do
    @refresh_token = "my_token"
    @client_id = "test_client_id"
    @client_secret = "test_client_secret"
    @metadata_uri = "salesforce.com"
    @instance_uri = "test-salesforce.com"
    @client = Salesforceapi::Rest::Client.new(@refresh_token, @metadata_uri, @client_id, @client_secret)
  end

  it "should get the resources information" do
    allow(SalesforceApi::Request).to receive(:do_request).with("POST", any_args).and_return(mock_response);
    expect(SalesforceApi::Request).to receive(:do_request).with("GET", @instance_uri + "/services/data/v54.0", headers, nil).and_return(mock_response)
    @client.resources
  end


  protected

  def headers
    {
      "Authorization" => "OAuth " + @refresh_token,
      "content-Type" => 'application/json'
    }
  end

  def mock_response
    response = double(
      :code => 200,
      :body => {
        "instance_url" => @instance_uri,
        "access_token" => @refresh_token
      }.to_json,
      :success? => true
    )
    response
  end
end
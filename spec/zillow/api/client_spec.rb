require 'rails_helper'

RSpec.describe Zillow::Api::Client do

  let(:client)  { Zillow::Api::Client }
  before(:each) { client.config.api_key = SecureRandom.uuid }

  context 'API key enforcement' do
    it 'should raise an exception unless configured' do
      client.config.api_key = nil
      expect { client.url 'AnyGivenEndpoint'  }.to raise_error(Zillow::Api::Exception::ZWSIDMissing)
    end
  end

  context 'convienence functionality (#method_missing)' do
    it 'should camelize the endpoint name' do
      allow(client).to receive(:get).and_return(nil)
      expect(client).to receive(:url).with('AnyGivenEndpoint',{})
      client.any_given_endpoint
    end
  end

  context 'URL interpolation (#url)' do
    it 'should form-encode parameter data in the URL' do
      params = { 'zws-id' => 1, a: 123, b: "something with crazy characters in it! like these #$%^&*(*&^%$)}"  }
      expect( client.url('SomeEndpoint',params).split('?').last.gsub('zws-id=1&','').gsub('&zws-id=1','') ).to eq("a=123&b=something+with+crazy+characters+in+it%21+like+these+%23%24%25%5E%26%2A%28%2A%26%5E%25%24%29%7D")
    end

    it 'should include the ZWS ID in the URL' do
      known_zws_id          = SecureRandom.uuid
      client.config.api_key = known_zws_id
      expect( client.url 'AnyGivenEndpoint' ).to eq("http://www.zillow.com/webservice/AnyGivenEndpoint.htm?zws-id=#{known_zws_id}")
    end

    it 'should raise an exception if a nil endpoint is passed to it' do
      expect{ client.url nil }.to raise_error(Zillow::Api::Exception::InvalidRequestError)
    end
  end

  context 'exception handling (#parse_response)' do
    # tons of cases to test here :)
  end

  context 'XML traversal (#parse_results)' do
    let(:actual_data) { { a: 1, b: 2 } }
    it 'should raise an exception if the result hash format is unexpected' do
      expect{ client.parse_results(actual_data) }.to raise_error(Zillow::Api::Exception::UnableToParseResponseError)
    end
    
    it 'should convert a single result hash into an array' do
      hash = { 'response' => { 'results' => { 'result' => actual_data } } }
      expect( client.parse_results hash ).to eq([actual_data])
    end
  end

end

module Zillow
  module Api

    module Exception
      ZillowError = Class.new(StandardError)
      %w[InvalidRequestError ExactMatchNotFoundError NoResultsError
        UnableToParseResponseError ServiceError ZWSIDInvalid
        ZWSIDMissing ServiceUnavailable].each do |klass_name|
          const_set klass_name, Class.new(ZillowError)
      end
    end

    class Client < RestClient::Request
      extend Zillow::Api::Exception
      include ActiveSupport::Configurable

      class << self

        def url(endpoint_name,params={})
          raise ZWSIDMissing.new, 'Zillow API key (zws-id) not specified' unless config.api_key.present?
          raise InvalidRequestError.new, 'No endpoint specified' if endpoint_name.blank?
          params = { 'zws-id' => config.api_key }.merge(params)
          "http://www.zillow.com/webservice/#{endpoint_name}.htm?#{params.to_query}"
        end

        def get(url,params={})
          parse_response self.new(method: 'get', url: url, payload: params).execute
        end

        def parse_results(response_data)
          result_or_results = response_data['response']['results']['result']
          result_or_results.is_a?(Array) ? result_or_results : [ result_or_results ]
        rescue => e
          raise UnableToParseResponseError.new, "Unknown data format encountered: #{e.message}"
        end

        def parse_response(response)
          response_data = Nori.new.parse(response)

          # munge around the XML to get at the actual data
          begin
            response_data = response_data[response_data.keys.first]
          rescue => e
            raise UnableToParseResponseError.new , e.message
          end

          # seems like all responses are 200 OK, so check the response payload to see if
          # there was an error
          response_code = response_data['message']['code'].to_i
          message       = response_data['message']['text']

          return parse_results(response_data) if response_code == 0

          case response_code
          when 1
            raise ServiceError.new,               "Service error: #{message}"
          when 2
            raise ZWSIDInvalid.new,               "Invalid Zillow API key (zws-id)"
          when 3, 4, 505
            raise ServiceUnavailable.new,         "The Zillow API is currently unavailable"
          when 500, 501, 506
            raise InvalidRequestError.new,        message.gsub('Error: ','').capitalize
          when 502
            raise NoResultsError.new,             "Sorry, the address you provided is not found in Zillow's property database."
          when 503, 504
            raise InvalidRequestError.new,        "Failed to resolve city/state (or zip code), or no coverage: #{message}"
          when 507, 508
            raise ExactMatchNotFoundError.new,    "No exact match found. Verify that the given address is correct."
          else
            raise UnableToParseResponseError.new, "Unknown response code #{response_code}: #{message}"
          end
        end

        # as far as I can tell, all data APIs are GET requests
        def method_missing(m,params={})
          get url(m.to_s.camelize,params)
        end

      end
    end
  end
end

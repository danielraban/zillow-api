class SearchController < ApplicationController
  before_action :fetch_results

  def search
  end

  protected

    def fetch_results
      return unless request.post?
      begin
        now = Time.now.to_f
        @results  = Zillow::Api::Client.get_search_results params.slice(:address, :citystatezip)
        @results  = [ @results ] unless @results.is_a?(Array)
        @duration = ( Time.now.to_f - now ).round(2)
      rescue Zillow::Api::Exception::ZillowError => e
        @exception = e
      end
    end

end

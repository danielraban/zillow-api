# we only need to_prepare in development when our
# code is reloaded on every request

Rails.application.config.to_prepare do
  Zillow::Api::Client.config.api_key = Rails.application.secrets.zillow_api_key
end

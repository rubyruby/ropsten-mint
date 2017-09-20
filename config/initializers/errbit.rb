if Rails.env.production? || Rails.env.staging?
  Airbrake.configure do |config|
    config.api_key = Rails.application.secrets.errbit[:key]
    config.host    = Rails.application.secrets.errbit[:host]
    config.port    = 80
    config.secure  = config.port == 443
  end
end
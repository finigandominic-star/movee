# httplog is only loaded in development (see Gemfile).
# Don't log request/response bodies: Active Storage uploads to Cloudinary
# would otherwise dump raw image bytes into the log and terminal.
if defined?(HttpLog)
  HttpLog.configure do |config|
    config.log_data = false
    config.log_response = false
    config.log_headers = false
  end
end

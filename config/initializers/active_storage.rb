Rails.application.config.after_initialize do
  ActiveStorage::Current.url_options = { host: "http://localhost:3634" }
end

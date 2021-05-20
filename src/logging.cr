require "placeos-log-backend"

require "./constants"

module PlaceOS::Frontends::Logging
  ::Log.progname = APP_NAME
  log_level = PlaceOS::Frontends.production? ? Log::Severity::Info : Log::Severity::Debug
  ::Log.setup "*", log_level, PlaceOS::LogBackend.log_backend
end

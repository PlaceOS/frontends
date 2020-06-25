# Application dependencies
require "action-controller"
require "log_helper"

# Application code
require "./placeos-frontends"

# Server required after application controllers
require "action-controller/server"

# Add handlers that should run before your application
ActionController::Server.before(
  ActionController::ErrorHandler.new(PlaceOS::Frontends::PROD, ["X-Request-ID"]),
  ActionController::LogHandler.new
)

# Configure logging
log_level = PlaceOS::Frontends::PROD ? Log::Severity::Info : Log::Severity::Debug
::Log.setup "*", log_level, PlaceOS::Frontends::LOG_BACKEND

# Application dependencies
require "action-controller"

# Application code
require "./logging"
require "./placeos-frontends"

# Server required after application controllers
require "action-controller/server"

# Add handlers that should run before your application
ActionController::Server.before(
  ActionController::ErrorHandler.new(PlaceOS::Frontends::PROD, ["X-Request-ID"]),
  ActionController::LogHandler.new(ms: true)
)

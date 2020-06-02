require "action-controller/logger"
require "log_helper"

module PlaceOS::Frontends
  LOG_BACKEND = ActionController.default_backend
  APP_NAME    = "PlaceOS Frontend Loader"
  VERSION     = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
end

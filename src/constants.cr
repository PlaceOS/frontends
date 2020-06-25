require "action-controller/logger"
require "secrets-env"
require "log_helper"

module PlaceOS::Frontends
  LOG_BACKEND = ActionController.default_backend
  APP_NAME    = "PlaceOS Frontend Loader"
  VERSION     = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}

  PROD = ENV["ENV"]? == "production"

  # defaults used in `./app.cr`
  HOST = ENV["PLACE_LOADER_HOST"]? || "127.0.0.1"
  PORT = (ENV["PLACE_LOADER_PORT"]? || 3000).to_i

  # settings for `./placeos-frontends/loader.cr`
  WWW      = ENV["PLACE_LOADER_WWW"]? || "www"
  CRON     = ENV["PLACE_LOADER_CRON"]? || "0 * * * *"
  GIT_USER = ENV["PLACE_LOADER_GIT_USER"]?
  GIT_PASS = ENV["PLACE_LOADER_GIT_PASS"]?

  # NOTE:: following used in `./placeos-frontends/client.cr`
  # URI.parse(ENV["PLACE_LOADER_URI"]? || "http://127.0.0.1:3000")
  # Independent of this file as used in other projects
end

require "./base"
require "../constants"

module PlaceOS::Frontends::Api
  class Root < Base
    base "/api/frontends/v1"

    get "/", :root do
      head :ok
    end

    get "/version", :version do
      render :ok, json: {
        version: VERSION.to_s,
      }
    end
  end
end

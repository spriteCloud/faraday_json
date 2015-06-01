#
# FaradayJSON
# https://github.com/spriteCloud/faraday_json
#
# Copyright (c) 2015 spriteCloud B.V. and other FaradayJSON contributors.
# All rights reserved.
#

require 'faraday'

module FaradayJSON
  autoload :ParseJson,       'faraday_json/parse_json'

  if Faraday::Middleware.respond_to? :register_middleware
    Faraday::Request.register_middleware \
      :json     => lambda { EncodeJson }

    Faraday::Response.register_middleware \
      :json     => lambda { ParseJson },
      :json_fix => lambda { ParseJson::MimeTypeFix }
  end
end

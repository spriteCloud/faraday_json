#
# FaradayJSON
# https://github.com/spriteCloud/faraday_json
#
# Copyright (c) 2015 spriteCloud B.V. and other FaradayJSON contributors.
# All rights reserved.
#

require 'faraday'
require 'faraday_json/encoding'

module FaradayJSON
  # Request middleware that encodes the body as JSON.
  #
  # Processes only requests with matching Content-type or those without a type.
  # If a request doesn't have a type but has a body, it sets the Content-type
  # to JSON MIME-type.
  #
  # Doesn't try to encode bodies that already are in string form.
  class EncodeJson < Faraday::Middleware
    CONTENT_TYPE   = 'Content-Type'.freeze
    CONTENT_LENGTH = 'Content-Length'.freeze
    MIME_TYPE      = 'application/json'.freeze
    MIME_TYPE_UTF8 = 'application/json; charset=utf-8'.freeze

    include ::FaradayJSON::Encoding

    dependency do
      require 'json' unless defined?(::JSON)
    end

    def call(env)
      if process_request?(env)
        body = env[:body]

        # Detect and honour input charset. Basically, all requests without a
        # charset should be considered malformed, but we can make a best guess.
        # Whether the body is a string or another data structure does not
        # matter: all strings *contained* within it must be encoded properly.
        charset = request_charset(env)

        # Strip BOM, if any
        body = strip_bom(body, charset, { 'default_encoding' => 'us-ascii' })

        # Transcode to UTF-8
        body = to_utf8(body, charset, { 'force_input_charset' => true })

        # If the body is a stirng, we assume it's already JSON. No further
        # processing is necessary.
        # XXX Is :to_str really a good indicator for Strings? Taken from old
        #     code.
        if not body.respond_to?(:to_str)
          # If body isn't a string yet, we need to encode it. We also know it's
          # then going to be UTF-8, because JSON defaults to that.
          # Thanks to to_utf8 above, JSON.dump should not have any issues here.
          body = ::JSON.dump(body)
        end

        env[:body] = body

        # We'll add a content length, because otherwise we're relying on every
        # component down the line properly interpreting UTF-8 - that can fail.
        env[:request_headers][CONTENT_LENGTH] ||= env[:body].bytesize

        # Always base the encoding we're sending in the content type header on
        # the string encoding.
        env[:request_headers][CONTENT_TYPE] = MIME_TYPE_UTF8
      end
      @app.call env
    end

    def process_request?(env)
      type = request_type(env)
      has_body?(env) and (type.empty? or type == MIME_TYPE)
    end

    def request_charset(env)
      enc = env[:request_headers][CONTENT_TYPE].to_s
      enc = enc.split(';', 2).last if enc.index(';')
      enc = enc.split('=', 2).last if enc.index('=')
      return enc
    end

    def has_body?(env)
      body = env[:body] and !(body.respond_to?(:to_str) and body.empty?)
    end

    def request_type(env)
      type = env[:request_headers][CONTENT_TYPE].to_s
      type = type.split(';', 2).first if type.index(';')
      type
    end
  end
end

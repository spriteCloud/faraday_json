#
# FaradayJSON
# https://github.com/spriteCloud/faraday_json
#
# Copyright (c) 2015 spriteCloud B.V. and other FaradayJSON contributors.
# All rights reserved.
#

require 'faraday_json/encoding'

module FaradayJSON
  # Public: Parse response bodies as JSON.
  class ParseJson < Faraday::Middleware
    CONTENT_TYPE = 'Content-Type'.freeze

    include ::FaradayJSON::Encoding

    dependency do
      require 'json' unless defined?(::JSON)
    end

    def initialize(app = nil, options = {})
      super(app)
      @options = options
      @content_types = Array(options[:content_type])
    end

    def call(environment)
      @app.call(environment).on_complete do |env|
        if process_response_type?(response_type(env)) and parse_response?(env)
          process_response(env)
        end
      end
    end

    def process_response(env)
      env[:raw_body] = env[:body] if preserve_raw?(env)
      body = env[:body]

      # Body will be in an unknown encoding. Use charset field to coerce it to
      # internal UTF-8.
      charset = response_charset(env)
      if charset.nil? or charset.empty?
        charset = 'utf-8'
      end

      # We must ensure we're interpreting the body as the right charset. First,
      # strip the BOM (if any).
      body = strip_bom(body, charset, { 'default_encoding' => 'us-ascii' })

      # Transcode to UTF-8
      body = to_utf8(body, charset, { 'force_input_charset' => true })

      # Now that's done, parse the JSON.
      ret = nil
      begin
        ret = ::JSON.parse(body) unless body.strip.empty?
      rescue StandardError, SyntaxError => err
        raise err if err.is_a? SyntaxError and err.class.name != 'Psych::SyntaxError'
        raise Faraday::Error::ParsingError, err
      end
      env[:body] = ret
    end

    def response_type(env)
      type = env[:response_headers][CONTENT_TYPE].to_s
      type = type.split(';', 2).first if type.index(';')
      type
    end

    def response_charset(env)
      header = env[:response_headers][CONTENT_TYPE].to_s
      if header.index(';')
        header.split(';').each do |part|
          if part.index('charset=')
            return part.split('charset=', 2).last
          end
        end
      end
      return nil
    end

    def process_response_type?(type)
      @content_types.empty? or @content_types.any? { |pattern|
        pattern.is_a?(Regexp) ? type =~ pattern : type == pattern
      }
    end

    def parse_response?(env)
      env[:body].respond_to? :to_str
    end

    def preserve_raw?(env)
      env[:request].fetch(:preserve_raw, @options[:preserve_raw])
    end



    # DRAGONS
    module OptionsExtension
      attr_accessor :preserve_raw

      def to_hash
        super.update(:preserve_raw => preserve_raw)
      end

      def each
        return to_enum(:each) unless block_given?
        super
        yield :preserve_raw, preserve_raw
      end

      def fetch(key, *args)
        if :preserve_raw == key
          value = __send__(key)
          value.nil? ? args.fetch(0) : value
        else
          super
        end
      end
    end

    if defined?(Faraday::RequestOptions)
      begin
        Faraday::RequestOptions.from(:preserve_raw => true)
      rescue NoMethodError
        Faraday::RequestOptions.send(:include, OptionsExtension)
      end
    end
  end # class ParseJson

  # Public: Override the content-type of the response with "application/json"
  # if the response body looks like it might be JSON, i.e. starts with an
  # open bracket.
  #
  # This is to fix responses from certain API providers that insist on serving
  # JSON with wrong MIME-types such as "text/javascript".
  class ParseJsonMimeTypeFix < ParseJson
    MIME_TYPE = 'application/json'.freeze

    def process_response(env)
      old_type = env[:response_headers][CONTENT_TYPE].to_s
      new_type = MIME_TYPE.dup
      new_type << ';' << old_type.split(';', 2).last if old_type.index(';')
      env[:response_headers][CONTENT_TYPE] = new_type
    end

    BRACKETS = %w- [ { -
    WHITESPACE = [ " ", "\n", "\r", "\t" ]

    def parse_response?(env)
      super and BRACKETS.include? first_char(env[:body])
    end

    def first_char(body)
      idx = -1
      begin
        char = body[idx += 1]
        char = char.chr if char
      end while char and WHITESPACE.include? char
      char
    end
  end # class ParseJson

end

# deprecated alias
Faraday::Response::ParseJson = FaradayJSON::ParseJson

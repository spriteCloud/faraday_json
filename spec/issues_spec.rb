# encoding: utf-8

require 'helper'
require 'faraday_json/encode_json'

describe FaradayJSON::EncodeJson do
  let(:middleware) { described_class.new(lambda{|env| env}) }

  def process(body, content_type = nil)
    env = {:body => body, :request_headers => Faraday::Utils::Headers.new}
    env[:request_headers]['content-type'] = content_type if content_type
    middleware.call(faraday_env(env))
  end

  def result_body() result[:body] end
  def result_type() result[:request_headers]['content-type'] end
  def result_length() result[:request_headers]['content-length'].to_i end


  ### Test cases specifically for filed issues
  context "issue #2: encoding an object with a contained array" do
    data = {
      :some_array => [1, 2, 3],
    }

    # Passing that data with a charset should do the right thing.
    let(:result) {
      process(data, "application/json; charset=utf-8")
    }

    it "encodes body" do
      expect(result_body).to eq("{\"some_array\":[1,2,3]}")
    end
  end
end

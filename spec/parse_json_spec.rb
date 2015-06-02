# encoding: utf-8

require 'helper'
require 'faraday_json/parse_json'

describe FaradayJSON::ParseJson, :type => :response do
  context "no type matching" do
    it "doesn't change nil body" do
      expect(process(nil).body).to be_nil
    end

    it "nullifies empty body" do
      expect(process('').body).to be_nil
    end

    it "parses json body" do
      response = process('{"a":1}')
      expect(response.body).to eq('a' => 1)
      expect(response.env[:raw_body]).to be_nil
    end
  end

  context "with preserving raw" do
    let(:options) { {:preserve_raw => true} }

    it "parses json body" do
      response = process('{"a":1}')
      expect(response.body).to eq('a' => 1)
      expect(response.env[:raw_body]).to eq('{"a":1}')
    end

    it "can opt out of preserving raw" do
      response = process('{"a":1}', nil, :preserve_raw => false)
      expect(response.env[:raw_body]).to be_nil
    end
  end

  context "with regexp type matching" do
    let(:options) { {:content_type => /\bjson$/} }

    it "parses json body of correct type" do
      response = process('{"a":1}', 'application/x-json')
      expect(response.body).to eq('a' => 1)
    end

    it "ignores json body of incorrect type" do
      response = process('{"a":1}', 'text/json-xml')
      expect(response.body).to eq('{"a":1}')
    end
  end

  context "with array type matching" do
    let(:options) { {:content_type => %w[a/b c/d]} }

    it "parses json body of correct type" do
      expect(process('{"a":1}', 'a/b').body).to be_a(Hash)
      expect(process('{"a":1}', 'c/d').body).to be_a(Hash)
    end

    it "ignores json body of incorrect type" do
      expect(process('{"a":1}', 'a/d').body).not_to be_a(Hash)
    end
  end

  it "chokes on invalid json" do
    ['{!', '"a"', 'true', 'null', '1'].each do |data|
      expect{ process(data) }.to raise_error(Faraday::Error::ParsingError)
    end
  end

  context "with mime type fix" do
    let(:middleware) {
      app = FaradayJSON::ParseJsonMimeTypeFix.new(lambda {|env|
        Faraday::Response.new(env)
      }, :content_type => /^text\//)
      described_class.new(app, :content_type => 'application/json')
    }

    it "ignores completely incompatible type" do
      response = process('{"a":1}', 'application/xml')
      expect(response.body).to eq('{"a":1}')
    end

    it "ignores compatible type with bad data" do
      response = process('var a = 1', 'text/javascript')
      expect(response.body).to eq('var a = 1')
      expect(response['content-type']).to eq('text/javascript')
    end

    it "corrects compatible type and data" do
      response = process('{"a":1}', 'text/javascript')
      expect(response.body).to be_a(Hash)
      expect(response['content-type']).to eq('application/json')
    end

    it "corrects compatible type even when data starts with whitespace" do
      response = process(%( \r\n\t{"a":1}), 'text/javascript')
      expect(response.body).to be_a(Hash)
      expect(response['content-type']).to eq('application/json')
    end
  end

  context "HEAD responses" do
    it "nullifies the body if it's only one space" do
      response = process(' ')
      expect(response.body).to be_nil
    end

    it "nullifies the body if it's two spaces" do
      response = process(' ')
      expect(response.body).to be_nil
    end
  end

  ### Unicode test cases
  # Ruby 1.8 will almost certainly fail if there is no charset given in a header.
  # In Ruby >1.8, we have some more methods for guessing well.

  ### All Ruby versions should work with a charset given.
  context "with utf-8 encoding" do
    it "parses json body" do
      response = process(test_encode('{"a":"ü"}', 'utf-8'), 'application/json; charset=utf-8')
      expect(response.body).to eq('a' => 'ü')
    end
  end

  context "with utf-16be encoding" do
    it "parses json body" do
      response = process(test_encode('{"a":"ü"}', 'utf-16be'), 'application/json; charset=utf-16be')
      expect(response.body).to eq('a' => 'ü')
    end
  end

  context "with utf-16le encoding" do
    it "parses json body" do
      response = process(test_encode('{"a":"ü"}', 'utf-16le'), 'application/json; charset=utf-16le')
      expect(response.body).to eq('a' => 'ü')
    end
  end

  context "with iso-8859-15 encoding" do
    it "parses json body" do
      response = process(test_encode('{"a":"ü"}', 'iso-8859-15'), 'application/json; charset=iso-8859-15')
      expect(response.body).to eq('a' => 'ü')
    end
  end

  ### Ruby versions > 1.8 should be able to guess missing charsets at times.
  if not RUBY_VERSION.start_with?("1.8")
    context "with utf-8 encoding without content type" do
      it "parses json body" do
        response = process(test_encode('{"a":"ü"}', 'utf-8'))
        expect(response.body).to eq('a' => 'ü')
      end
    end

    context "with utf-16be encoding without content type" do
      it "parses json body" do
        response = process(test_encode('{"a":"ü"}', 'utf-16be'))
        expect(response.body).to eq('a' => 'ü')
      end
    end

    context "with utf-16le encoding without content type" do
      it "parses json body" do
        response = process(test_encode('{"a":"ü"}', 'utf-16le'))
        expect(response.body).to eq('a' => 'ü')
      end
    end

    context "with iso-8859-15 encoding without content type" do
      it "parses json body" do
        response = process(test_encode('{"a":"ü"}', 'iso-8859-15'))
        expect(response.body).to eq('a' => 'ü')
      end
    end
  end

  ### Dealing with files in various encoding should ideally be easy
  FILES = {
    'spec/data/iso8859-15_file.json' => 'iso-8859-15',
    'spec/data/utf16be_file.json' => 'utf-16be',
    'spec/data/utf16le_file.json' => 'utf-16le',
    'spec/data/utf8_file.json' => 'utf-8',
  }

if not RUBY_VERSION.start_with?("1.8")
  FILES.each do |fname, enc|
    context "reading #{enc} encoded file '#{fname}'" do
      # Read the string from file; read binary/with encoding. Ruby 1.8 will
      # ignore this, but must still work.
      data = File.new(fname, "rb:#{enc}").read

      # Passing that data with a charset should do the right thing.
      it "decodes body" do
        response = process(data)
        expect(response.body).to eq('a' => "Hellö, Wörld!")
      end
    end
  end
end

  FILES.each do |fname, enc|
    context "reading #{enc} encoded file '#{fname}' as binary" do
      # Read the string from file; read binary/with encoding. Ruby 1.8 will
      # ignore this, but must still work.
      data = File.new(fname, "rb").read

      # Passing that data with a charset should do the right thing.
      it "decodes body" do
        response = process(data, "application/json; charset=#{enc}")
        expect(response.body).to eq('a' => "Hellö, Wörld!")
      end
    end
  end

end

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

  context "no body" do
    let(:result) { process(nil) }

    it "doesn't change body" do
      expect(result_body).to be_nil
    end

    it "doesn't add content type" do
      expect(result_type).to be_nil
    end
  end

  context "empty body" do
    let(:result) { process('') }

    it "doesn't change body" do
      expect(result_body).to be_empty
    end

    it "doesn't add content type" do
      expect(result_type).to be_nil
    end
  end

  context "string body" do
    let(:result) { process('{"a":1}') }

    it "doesn't change body" do
      expect(result_body).to eq('{"a":1}')
    end

    it "adds content type" do
      expect(result_type).to eq('application/json; charset=utf-8')
    end
  end

  context "object body" do
    let(:result) { process({:a => 1}) }

    it "encodes body" do
      expect(result_body).to eq('{"a":1}')
    end

    it "adds content type" do
      expect(result_type).to eq('application/json; charset=utf-8')
    end
  end

  context "empty object body" do
    let(:result) { process({}) }

    it "encodes body" do
      expect(result_body).to eq('{}')
    end
  end

  context "object body with json type" do
    let(:result) { process({:a => 1}, 'application/json; charset=utf-8') }

    it "encodes body" do
      expect(result_body).to eq('{"a":1}')
    end

    it "doesn't change content type" do
      expect(result_type).to eq('application/json; charset=utf-8')
    end
  end

  context "object body with incompatible type" do
    let(:result) { process({:a => 1}, 'application/xml; charset=utf-8') }

    it "doesn't change body" do
      expect(result_body).to eq({:a => 1})
    end

    it "doesn't change content type" do
      expect(result_type).to eq('application/xml; charset=utf-8')
    end
  end

  ### Unicode test cases
  # Ruby 1.8 will almost certainly fail if there is no charset given in a header.
  # In Ruby >1.8, we have some more methods for guessing well.

  ### All Ruby versions should work with a charset given.
  context "utf-8 in string body" do
    let(:result) { process('{"a":"ä"}', 'application/json; charset=utf-8') }

    it "doesn't change body" do
      expect(result_body).to eq('{"a":"ä"}')
    end

    it "doesn't change content type" do
      expect(result_type).to eq('application/json; charset=utf-8')
    end

    it "adds content length" do
      expect(result_length).to eq(10)
    end
  end

  context "utf-8 in object body" do
    let(:result) { process({:a => "ä"}, 'application/json; charset=utf-8') }

    it "encodes body" do
      expect(result_body).to eq('{"a":"ä"}')
    end

    it "doesn't change content type" do
      expect(result_type).to eq('application/json; charset=utf-8')
    end

    it "adds content length" do
      expect(result_length).to eq(10)
    end
  end

  context "non-unicode in string body" do
    let(:result) {
      process(test_encode('{"a":"ä"}', 'iso-8859-15'), 'application/json; charset=iso-8859-15')
    }

    it "changes body" do
      expect(result_body).to eq('{"a":"ä"}')
    end

    it "changes content type" do
      expect(result_type).to eq('application/json; charset=utf-8')
    end

    it "adds content length" do
      expect(result_length).to eq(10)
    end
  end

  context "non-unicode in object body" do
    let(:result) {
      process({:a => test_encode('ä', 'iso-8859-15')}, 'application/json; charset=iso-8859-15')
    }

    it "encodes body" do
      expect(result_body).to eq('{"a":"ä"}')
    end

    it "changes content type" do
      expect(result_type).to eq('application/json; charset=utf-8')
    end

    it "adds content length" do
      expect(result_length).to eq(10)
    end
  end

  context "non-utf-8 in string body" do
    let(:result) {
      process(test_encode('{"a":"ä"}', 'utf-16be'), 'application/json; charset=utf-16be')
    }

    it "changes body" do
      expect(result_body).to eq('{"a":"ä"}')
    end

    it "changes content type" do
      expect(result_type).to eq('application/json; charset=utf-8')
    end

    it "adds content length" do
      expect(result_length).to eq(10)
    end
  end

  context "non-utf-8 in object body" do
    let(:result) {
      process({:a => test_encode('ä', 'utf-16le')}, 'application/json; charset=utf-16le')
    }

    it "encodes body" do
      expect(result_body).to eq('{"a":"ä"}')
    end

    it "changes content type" do
      expect(result_type).to eq('application/json; charset=utf-8')
    end

    it "adds content length" do
      expect(result_length).to eq(10)
    end
  end


  ### Ruby versions > 1.8 should be able to guess missing charsets at times.
  if not RUBY_VERSION.start_with?("1.8")
    context "utf-8 in string body without content type" do
      let(:result) { process('{"a":"ä"}') }

      it "doesn't change body" do
        expect(result_body).to eq('{"a":"ä"}')
      end

      it "adds content type" do
        expect(result_type).to eq('application/json; charset=utf-8')
      end

      it "adds content length" do
        expect(result_length).to eq(10)
      end
    end

    context "utf-8 in object body without content type" do
      let(:result) { process({:a => "ä"}) }

      it "encodes body" do
        expect(result_body).to eq('{"a":"ä"}')
      end

      it "adds content type" do
        expect(result_type).to eq('application/json; charset=utf-8')
      end

      it "adds content length" do
        expect(result_length).to eq(10)
      end
    end

    context "non-unicode in string body without content type" do
      let(:result) {
        process(test_encode('{"a":"ä"}', 'iso-8859-15'))
      }

      it "doesn't change body" do
        expect(result_body).to eq('{"a":"ä"}')
      end

      it "adds content type" do
        expect(result_type).to eq('application/json; charset=utf-8')
      end

      it "adds content length" do
        expect(result_length).to eq(10)
      end
    end

    context "non-unicode in object body without content type" do
      let(:result) {
        process({:a => test_encode('ä', 'iso-8859-15')})
      }

      it "encodes body" do
        expect(result_body).to eq('{"a":"ä"}')
      end

      it "adds content type" do
        expect(result_type).to eq('application/json; charset=utf-8')
      end

      it "adds content length" do
        expect(result_length).to eq(10)
      end
    end

    context "non-utf-8 in string body without content type" do
      let(:result) {
        process(test_encode('{"a":"ä"}', 'utf-16be'))
      }


      it "doesn't change body" do
        expect(result_body).to eq('{"a":"ä"}')
      end

      it "adds content type" do
        expect(result_type).to eq('application/json; charset=utf-8')
      end

      it "adds content length" do
        expect(result_length).to eq(10)
      end
    end

    context "non-utf-8 in object body without content type" do
      let(:result) {
        process({:a => test_encode('ä', 'utf-16le')})
      }

      it "encodes body" do
        expect(result_body).to eq('{"a":"ä"}')
      end

      it "adds content type" do
        expect(result_type).to eq('application/json; charset=utf-8')
      end

      it "adds content length" do
        expect(result_length).to eq(10)
      end
    end

    ### Dealing with files in various encoding should ideally be easy
    FILES = {
      'spec/data/iso8859-15_file.json' => 'iso-8859-15',
      'spec/data/utf16be_file.json' => 'utf-16be',
      'spec/data/utf16le_file.json' => 'utf-16le',
      'spec/data/utf8_file.json' => 'utf-8',
    }


    FILES.each do |fname, enc|
      context "reading #{enc} encoded file '#{fname}'" do
        # Read the string from file; read binary/with encoding. Ruby 1.8 will
        # ignore this, but must still work.
        data = File.new(fname, "rb:#{enc}").read

        # Passing that data with a charset should do the right thing.
        let(:result) {
          process(data)
        }

        it "encodes body" do
          expect(result_body).to eq("{\"a\":\"Hellö, Wörld!\"}\n")
        end

        it "adds content type" do
          expect(result_type).to eq('application/json; charset=utf-8')
        end

        it "adds content length" do
          expect(result_length).to eq(24)
        end
      end
    end

    FILES.each do |fname, enc|
      context "reading #{enc} encoded file '#{fname}' as binary" do
        # Read the string from file; read binary/with encoding. Ruby 1.8 will
        # ignore this, but must still work.
        data = File.new(fname, "rb").read

        # Passing that data with a charset should do the right thing.
        let(:result) {
          process(data, "application/json; charset=#{enc}")
        }

        it "encodes body" do
          expect(result_body).to eq("{\"a\":\"Hellö, Wörld!\"}\n")
        end

        it "adds content type" do
          expect(result_type).to eq('application/json; charset=utf-8')
        end

        it "adds content length" do
          expect(result_length).to eq(24)
        end
      end
    end

  end # Ruby version > 1.8
end

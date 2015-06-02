#
# FaradayJSON
# https://github.com/spriteCloud/faraday_json
#
# Copyright (c) 2015 spriteCloud B.V. and other FaradayJSON contributors.
# All rights reserved.
#

module FaradayJSON

# Character encoding helper functions
module Encoding

# Two versions of transcode, one for Ruby 1.8 and one for greater versions.

if RUBY_VERSION.start_with?("1.8")

  def transcode(data, input_charset, output_charset, opts = {})
    # In Ruby 1.8, we pretty much have to believe the given charsets; there's
    # not a lot of choice.

    # If we don't have an input charset, we can't do better than US-ASCII.
    if input_charset.nil? or input_charset.empty?
      input_charset = opts.fetch('default_input_charset', 'us-ascii')
    end

    # The default output charset, on the other hand, should be UTF-8.
    if output_charset.nil? or output_charset.empty?
      output_charset = opts.fetch('default_output_charset', 'UTF-8//IGNORE')
    end

    # Transcode using iconv
    require 'iconv'
    return ::Iconv.conv(output_charset, input_charset, data)
  end

else # end ruby 1.8/start ruby > 1.8

  def transcode(data, input_charset, output_charset, opts = {})
    # Strings have an encode function in Ruby > 1.8
    if not data.respond_to?(:encode)
      return data
    end

    # If we don't have a charset, just use whatever is in the string
    # currently. If we do have a charset, we'll have to run some extra
    # checks.
    if not (input_charset.nil? or input_charset.empty?)
      # Check passed charset is *understood* by finding it. If this fails,
      # an exception is raised, which it also should be.
      canonical = ::Encoding.find(input_charset)

      # Second, ensure the canonical charset and the actual string encoding
      # are identical. If not, we'll have to do a little more than just
      # transcode to UTF-8.
      if canonical != data.encoding
        if opts.fetch('force_input_charset', false)
          data.force_encoding(canonical)
        else
          raise "Provided charset was #{canonical}, but data was #{data.encoding}"
        end
      end
    end

    # If there's no output charset, we should default to UTF-8.
    if output_charset.nil? or output_charset.empty?
      output_charset = opts.fetch('default_output_charset', 'UTF-8')
    end

    # Transcode!
    return data.encode(output_charset)
  end

end # ruby > 1.8

  # Convenient helper. Output is UTF-8. Input is either a string, or some data
  # data. There's a Ruby 1.8 version mostly because it has to iteratively convert
  # included strings.
if RUBY_VERSION.start_with?("1.8")

  def to_utf8(data, charset, opts = {})
    if data.is_a? Hash
      transcoded = {}
      data.each do |key, value|
        transcoded[to_utf8(key, charset, opts)] = to_utf8(value, charset, opts)
      end
      return transcoded
    elsif data.is_a? Array
      transcoded = []
      data.each do |value|
        transcoded << to_utf8(value, charest, opts)
      end
      return transcoded
    elsif data.is_a? String
      return transcode(data, charset, 'UTF-8//IGNORE', opts)
    else
      return data
    end
  end

else # end ruby 1.8/start ruby > 1.8

  def to_utf8(data, charset, opts = {})
    return transcode(data, charset, 'UTF-8', opts)
  end

end # ruby > 1.8


  # Helper function; strips a BOM for UTF-16 encodings
  def strip_bom(data, charset, opts = {})
    # Only need to do this on Strings
    if not data.is_a? String
      return data
    end

    # If the charset is given, it overrides string internal encoding.
    enc = get_dominant_encoding(data, charset, opts)

    # Make the encoding canonical (if we can find out about that).
    canonical = get_canonical_encoding(enc)

    # Determine what a BOM would look like.
    bom = get_bom(canonical)

    # We can't operate on data, we need a byte array.
    arr = data.each_byte.to_a

    # Match BOM
    found = true
    bom.each_index do |i|
      if bom[i] != arr[i]
        found = false
        break
      end
    end

    # So we may have found a BOM! Strip it.
    if found
      ret = arr[bom.length..-1].pack('c*')
      if ret.respond_to? :force_encoding
        ret.force_encoding(canonical)
      end
      return ret
    end

    # No BOM
    return data
  end

  # Given a String with (potentially, this depends on Ruby version) an encoding,
  # and a charset from a content-type header (which may be nil), determines the
  # dominant encoding. (Charset, if given, overrides internal encoding,
  # if present).
  def get_dominant_encoding(str, charset, opts = {})
    enc = nil
    if str.respond_to? :encoding
      enc = str.encoding
    end

    if charset.nil? or charset.empty?
      if enc.nil?
        default_encoding = opts.fetch('default_encoding', nil)
        if default_encoding.nil?
          raise "No charset provided, don't know what to do!" # FIXME
        end
        enc = default_encoding
      end
    else
      enc = charset
    end

    return enc
  end


  # Returns a canonical version of an encoding.
  def get_canonical_encoding(enc)
    if defined? ::Encoding and ::Encoding.respond_to? :find
      return ::Encoding.find(enc).to_s.downcase
    end
    return enc.downcase
  end


  # Given a (canonical) encoding, returns a BOM as an array of byte values. If
  # the given encoding does not have a BOM, an empty array is returned.
  def get_bom(enc)
    bom = []
    if enc.start_with?('utf16be') or enc.start_with?('utf-16be')
      bom = [0xfe, 0xff]
    elsif enc.start_with?('utf16le') or enc.start_with?('utf-16le')
      bom = [0xff, 0xfe]
    elsif enc.start_with?('utf8') or enc.start_with?('utf-8')
      bom = [0xef, 0xbb, 0xbf]
    elsif enc.start_with?('utf32be') or enc.start_with?('utf-32be')
      bom = [0x00, 0x00, 0xfe, 0xff]
    elsif enc.start_with?('utf32le') or enc.start_with?('utf-32le')
      bom = [0xff, 0xfe, 0x00, 0x00]
    end
    return bom
  end



  # Helper function for testing
  def bin_to_hex(data)
    if data.respond_to? :each_byte
      return data.each_byte.map { |b| b.to_s(16) }.join
    end
    return data
  end

end # module Encoding
end # module FaradayJSON

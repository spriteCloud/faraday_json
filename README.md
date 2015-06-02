# Introduction
This is a character encoding-aware JSON middleware for Faraday.

[![Gem Version](https://badge.fury.io/rb/faraday_json.svg)](http://badge.fury.io/rb/faraday_json)
[![Build Status](https://travis-ci.org/spriteCloud/faraday_json.svg)](https://travis-ci.org/spriteCloud/faraday_json)

The default JSON middleware from lostisland/faraday_middleware is not character
encoding aware. This is problematic because by default, Ruby performs I/O based
on locale settings. If your locale specifies one character encoding, but the
request or response body is encoded in another, you will end up with a Ruby
string that pretends to be one encoding, but cannot correctly be interpreted as
such.

Worse, Ruby 1.8 and later Ruby versions will not behave consistently, as 1.8
does not yet understand character encodings internally. There is a lengthy
discussion about this at https://bugs.ruby-lang.org/issues/2567 

Still worse, JSON used to specify UTF-8 encoding as mandatory, but now loosened
this to any Unicode character set. The result is that some JSON libraries still
only understand UTF-8.

This middleware fixes these issues rather brute-force by:

  - Accepting the Content-Type charset value as the correct encoding, and
    converting the body from Faraday adapters to this encoding.
  - Only sending UTF-8 encoded JSON, converting raw data if necessary.
  - Always setting the UTF-8 charset when sending this UTF-8 encoded JSON.

When no charset is provided, all bets are off. The correct default would be to
assume US-ASCII, but that may break some code. This middleware lets you override
this default.

## Installation

Add this line to your application's Gemfile:

    gem 'faraday_json'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install faraday_json

## Usage

```ruby
require 'faraday'
require 'faraday_middleware'  # optional
require 'faraday_json'        # replaces JSON handling from previous require

client = Faraday.new('http://some_url') do |conn|
  conn.request :json
  conn.response :json

  conn.adapter Faraday.default_adapter
end

client.post '/', :a => "röck döts"
```

1. `faraday_middleware` is not required for JSON handling.
1. Require `faraday_json` *after* `faraday_middleware` to override the behaviour
  from `faraday_middleware`.

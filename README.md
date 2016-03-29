# Aryll [![Build Status](https://travis-ci.org/kaupertmedia/kauperts_link_checker.svg?branch=master)](https://travis-ci.org/kaupertmedia/kauperts_link_checker)

**Aryll** is a simple library to check for the well-being of URLs. It supports HTTPS and IDN URIs.

## Installation

Add this line to your application's Gemfile:
```
 gem 'aryll'
```

And then execute:
```
 $ bundle
```

Or install it yourself as:
```
 $ gem install aryll
```

## Usage
It will check any object that responds to `url`:
```ruby
  status = Aryll.check!(my_url)
  unless status.ok?
    puts status
  end
```

You can ignore 301 permanent redirect that only add a trailing slash like this:
```ruby
  status = Aryll::LinkChecker.check!(url, ignore_trailing_slash_redirects: true)
  unless status.ok?
    # A redirect from http://example.com/foo to http://example.com/foo/ will be considered ok
  end
```

## I18n
The following keys are used to translate error messages using the I18n gem:

* `kauperts.link_checker.errors.timeout`: message when rescueing from Timeout::Error
* `kauperts.link_checker.errors.generic_network`: message when (currently) rescueing from all other exceptions

## Credits
**Aryll** is extracted from a maintenance task made for
[berlin.kauperts.de](https://berlin.kauperts.de) by [kaupert media gmbh](http://kaupertmedia.de).

## License
**Aryll** is released under a 3-clause BSD-licence. See the LICENSE file for details.


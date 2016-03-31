require "net/https"
require "simpleidn"
require 'aryll/version'
require 'aryll/link_checker'
require 'aryll/international_uri'
require 'aryll/status_message'

module Aryll

  # Immediately checks +url+ and returns the LinkChecker instance
  def check!(url, **options)
    checker = LinkChecker.new(url, **options)
    checker.check!
    checker
  end

  module_function :check!

end

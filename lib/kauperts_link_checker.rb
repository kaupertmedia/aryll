require "net/https"
require "simpleidn"
require "i18n"
require 'kauperts_link_checker/international_uri'

module Kauperts

  # Checks the status of an object which responds to +url+. The returned
  # status can be accessed via +status+. It contains either a string
  # representation of a numeric http status code or an error message.
  #
  # Supports HTTPS and IDN-domains.
  #
  #
  # The following keys are used to translate error messages using the I18n gem:
  # * <tt>kauperts.link_checker.errors.timeout</tt>: rescues from Timeout::Error
  # * <tt>kauperts.link_checker.errors.generic_network</tt>: (currently) rescues from all other exceptions
  # * <tt>kauperts.link_checker.status.redirect_permanently</tt>: translation for 301 permanent redirects
  class LinkChecker

    class << self
      attr_accessor :ignore_trailing_slash_redirects, :ignore_302_redirects

      def configure
        yield self
      end
    end

    attr_reader :url, :status, :ignore_trailing_slash_redirects, :ignore_302_redirects

    # === Parameters
    # * +url+: an arbitrary url which responds to +url+.
    # * +options+: optional configuration parameters, see below.
    #
    # === Available Options
    # * +ignore_trailing_slash_redirects+: ignores redirects to the same URI but only with an added trailing slash (default: false)
    def initialize(url, ignore_trailing_slash_redirects: false, ignore_302_redirects: false)
      @url = url

      @ignore_trailing_slash_redirects = ignore_trailing_slash_redirects || self.class.ignore_trailing_slash_redirects
      @ignore_302_redirects = ignore_302_redirects || self.class.ignore_302_redirects

    end

    # Checks the associated url url. Sets and returns +status+
    def check!
      begin
        uri = InternationalURI(url)
        if uri.scheme == 'https'
          http = Net::HTTP.new(uri.host , 443)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          response = http.start{ http.get2(uri.to_s) }
        else
          response = Net::HTTP.get_response(uri)
        end
        status = if response.code == '301'
                   @redirect_with_trailing_slash_only = "#{uri}/" == response['location']
                   "#{I18n.t :"kauperts.link_checker.status.redirect_permanently", :default => "Moved permanently"} (#{response['location']})"
                 else
                   response.code
                 end
      rescue Timeout::Error => e
        status = "#{I18n.t :"kauperts.link_checker.errors.timeout", :default => "Timeout"} (#{e.message})"
      rescue Exception => e
        status = "#{I18n.t :"kauperts.link_checker.errors.generic_network", :default => "Generic network error"} (#{e.message})"
      end
      @status = status
    end

    # Returns if a check has been run and the return code was '200 OK'
    # or if a 301 permanent redirect only added a trailing slash
    # while +ignore_trailing_slash_redirects+ has been set to true
    def ok?
      return true if @status == '200'
      return true if (@status == '302' and ignore_302_redirects)
      return true if (@redirect_with_trailing_slash_only == true and ignore_trailing_slash_redirects)

      false
    end

    # Immediately checks +url+ and returns the LinkChecker instance
    def self.check!(url, options = {})
      checker = new(url, options)
      checker.check!
      checker
    end

  end
end


require "net/https"
require 'simpleidn'
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
  class LinkChecker

    attr_reader :object, :status

    # === Parameters
    # * +object+: an arbitrary object which responds to +url+.
    def initialize(object)
      object.respond_to?(:url) ? @object = object : raise(ArgumentError.new("object doesn't respond to url"))
    end

    # Checks the associated url object. Sets and returns +status+
    def check!
      begin
        uri = parsed_uri(@object.url)
        if uri.scheme == 'https'
          http = Net::HTTP.new(uri.host , 443)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          response = http.start{ http.get2(uri.to_s) }
        else
          response = Net::HTTP.get_response(uri)
        end
        status = response.code
      rescue Timeout::Error => e
        status = "#{I18n.t :"kauperts.link_checker.errors.timeout", :default => "Timeout"} (#{e.message})"
      rescue Exception => e
        status = "#{I18n.t :"kauperts.link_checker.errors.generic_network", :default => "Generic network error"} (#{e.message})"
      end
      @status = status
    end

    # Returns if a check has been run and the return code was '200 OK'
    def ok?
      @status == '200'
    end

    # Immediately checks +object+ and returns the LinkChecker instance
    def self.check!(object)
      checker = new(object)
      checker.check!
      checker
    end

    protected

    # Transforms a possible IDN within +url+ into ASCII and returns
    # a parsed URI instance.
    def parsed_uri(url)
      url_without_protocol = /^http[s]?:\/\/(.+)/.match(url)[1]
      domain = url_without_protocol.split('/', 2)[0]
      idn_domain = SimpleIDN.to_ascii(domain)
      URI.parse(url.gsub(domain, idn_domain))
    end

  end
end

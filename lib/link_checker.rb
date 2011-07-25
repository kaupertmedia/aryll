require "net/https"
require 'simpleidn'
module Kauperts
  class LinkChecker

    attr_reader :object

    def initialize(object)
      object.respond_to?(:url) ? @object = object : raise(ArgumentError.new("object doesn't respond to url"))
    end

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
        status = "Zeitüberschreitung (#{e.message})"
      rescue Exception => e
        status = "Netzwerkfehler (#{e.message})"
      end
      [@object, status]
    end

    protected

    def parsed_uri(url)
      url_without_protocol = /^http[s]?:\/\/(.+)/.match(url)[1]
      domain = url_without_protocol.split('/', 2)[0]
      idn_domain = SimpleIDN.to_ascii(domain)
      URI.parse(url.gsub(domain, idn_domain))
    end

  end
end

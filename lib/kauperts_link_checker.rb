require "net/https"
require "simpleidn"
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

    attr_reader :configuration, :object, :status

		class Configuration < Struct.new(:ignore_trailing_slash_redirects)
		end

    # === Parameters
    # * +object+: an arbitrary object which responds to +url+.
		# * +options+: optional configuration parameters, see below.
		#
		# === Available Options
		# * +ignore_trailing_slash_redirects+: ignores redirects to the same URI but only with an added trailing slash (default: false)
    def initialize(object, options = {})
      object.respond_to?(:url) ? @object = object : raise(ArgumentError.new("object doesn't respond to url"))

			# Assign config variables
			@configuration = Configuration.new
			options = { :ignore_trailing_slash_redirects => false }.merge(options).each do |key, val|
				@configuration.send(:"#{key}=", val)
			end

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
      @status == '200' or (@redirect_with_trailing_slash_only == true and self.configuration.ignore_trailing_slash_redirects)
    end

    # Immediately checks +object+ and returns the LinkChecker instance
    def self.check!(object, options = {})
      checker = new(object, options)
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

module Aryll
  # Checks the status of a web address. The returned status can be accessed via
  # +status+. It contains either a string representation of a numeric http
  # status code or an error message.
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

    attr_reader :url, :status, :ignore_trailing_slash_redirects, :ignore_302_redirects,
      :open_timeout, :read_timeout, :user_agent

    # === Parameters
    # * +url+: URL, complete with protocol scheme
    # * +options+: optional configuration parameters, see below.
    #
    # === Available Options
    # * +ignore_trailing_slash_redirects+: ignores redirects to the same URI but only with an added trailing slash (default: false)
    # * +ignore_302_redirects+: ignores temporary redirects (default: false)
    # * +open_timeout+: Passed to Net::HTTP#open_timeout
    # * +read_timeout+: Passed to Net::HTTP#read_timeout
    def initialize(url, ignore_trailing_slash_redirects: false, ignore_302_redirects: false, open_timeout: 5, read_timeout: 10, user_agent: "Aryll Spider v#{Aryll::VERSION} (https://github.com/kaupertmedia/aryll)".freeze)
      @url = url

      @ignore_trailing_slash_redirects = ignore_trailing_slash_redirects || self.class.ignore_trailing_slash_redirects
      @ignore_302_redirects = ignore_302_redirects || self.class.ignore_302_redirects
      @open_timeout, @read_timeout = open_timeout, read_timeout
      @user_agent = user_agent
    end

    # Checks the associated url. Sets and returns +status+
    def check!
      @status = begin
                  if response.code == '301'
                    @redirect_with_trailing_slash_only = "#{uri}/" == response['location']
                    StatusMessage.moved_permanently response['location']
                  else
                    response.code
                  end
                rescue Timeout::Error => e
                  StatusMessage.timeout e.message
                rescue Exception => e
                  StatusMessage.generic e.message
                end
    end

    # Returns if a check has been run and the return code was '200 OK'
    # or if a 301 permanent redirect only added a trailing slash
    # while +ignore_trailing_slash_redirects+ has been set to true
    def ok?
      (status == '200') ||
        (status == '302' && ignore_302_redirects) ||
        [@redirect_with_trailing_slash_only, ignore_trailing_slash_redirects].all?
    end

    def uri
      @uri ||= InternationalURI(url)
    end

    private

    def response
      @response ||= begin
                      https_opts = { use_ssl: uri.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE }
                      Net::HTTP.start(uri.host, uri.port, https_opts) do |http|
                        request = Net::HTTP::Get.new uri, 'User-Agent' => user_agent
                        http.open_timeout = open_timeout
                        http.read_timeout = read_timeout
                        http.request request
                      end
                    end
    end

  end
end

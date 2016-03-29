module Aryll
  class LinkChecker

    class InternationalURI < Struct.new(:url)
      def domain
        @domain ||= url_without_protocol.split('/', 2)[0]
      end

      def idn_domain
        @idn_domain ||= SimpleIDN.to_ascii domain
      end

      def to_uri
        URI.parse(url.gsub(domain, idn_domain))
      end

      private

      def url_without_protocol
        @url_without_protocol ||= /^http[s]?:\/\/(.+)/.match(url)[1]
      end
    end

    def InternationalURI(url)
      InternationalURI.new(url).to_uri
    end

  end
end

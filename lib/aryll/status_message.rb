require 'i18n'

module Kauperts
  class LinkChecker

    class StatusMessage

      class << self

        def moved_permanently(message)
          t 'status.redirect_permanently', 'Moved permanently', message
        end

        def generic(message)
          t 'errors.generic_network', 'Generic network error', message
        end

        def timeout(message)
          t 'errors.timeout', 'Timeout', message
        end

        private

        def t(key, default, message)
          [
            I18n.t("kauperts.link_checker.#{key}", default: default),
            "(#{message})"
          ].join ' '
        end

      end

    end

  end
end

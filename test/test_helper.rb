if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

require 'bundler/setup'

require 'minitest/autorun'
require 'minitest/pride'
require 'webmock/minitest'

require 'kauperts_link_checker'

I18n.available_locales = :en

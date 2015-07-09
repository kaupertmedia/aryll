if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

require 'bundler/setup'

require 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'active_support'
require 'active_support/test_case'
require 'webmock/minitest'

require 'kauperts_link_checker'

ActiveSupport.test_order = :random
I18n.available_locales = :en

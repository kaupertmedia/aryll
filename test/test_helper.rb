require 'rubygems'
require 'bundler/setup'


require 'mocha'
require 'minitest'
require 'minitest/autorun'
require 'active_support'
require 'active_support/test_case'
require 'mocha/mini_test'

require 'kauperts_link_checker'

ActiveSupport.test_order = :random
I18n.available_locales = :en

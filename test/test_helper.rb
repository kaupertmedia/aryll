require 'rubygems'
require 'bundler/setup'


require 'minitest/autorun'
require 'active_support/test_case'
Bundler.require(:default, :development)

I18n.available_locales = :en

require 'kauperts_link_checker'

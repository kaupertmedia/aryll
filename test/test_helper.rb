if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

require 'bundler/setup'

require 'minitest/autorun'
require 'minitest/pride'
require 'webmock/minitest'

require 'aryll'

I18n.available_locales = :en

module MiniTest
  module Assertions

    def assert_change(change_proc)
      before = change_proc.call
      yield
      after  = change_proc.call
      refute_equal before, after
    end

  end

  module Expectations
    infect_an_assertion :assert_change, :must_change, :block
  end
end

require 'test_helper'

class LinkCheckerTest < ActiveSupport::TestCase

  test "should accept objects responding to url" do

    assert_nothing_raised do
      assert checker.new(url_object)
    end

    assert_raises ArgumentError do
      checker.new(Object.new)
    end

  end


  protected

  def checker
    Kauperts::LinkChecker
  end

  def url_object(url = nil)
    obj = mock('url_object')
    url ||= 'http://www.google.de'
    obj.stubs(:url).returns(url)
    obj
  end

end

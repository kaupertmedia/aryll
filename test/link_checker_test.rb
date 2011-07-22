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

  test "should expose object" do
    obj = checker.new(url_object)
    assert_respond_to obj, :object
  end

  test "should have check! method" do
    url = url_object
    obj = checker.new(url)
    assert_respond_to obj, :check!
  end

  test "should return status array with 200" do
    stub_net_http!
    obj = checker.new(url)
    assert_equal [url, "200"], obj.check!
  end

  test "should return status array with 404" do
    stub_net_http!
    obj = checker.new(url)
    assert_equal [url, "200"], obj.check!
  end

  test "should handle time out exceptions" do
    flunk "TODO"
  end

  test "should handle generice network problem" do
    flunk "TODO"
  end

  test "should handle domain with umlauts" do
    flunk "TODO"
  end

  test "should handle ssl protocol" do
    flunk "TODO"
  end

  protected

  def checker
    Kauperts::LinkChecker
  end

  def stub_net_http!(return_code = "200")
    return_code = return_code.to_s
    mock_response = mock('response')
    mock_response.stubs(:code).returns(return_code)
    Net::HTTP.stubs(:get_response).returns(mock_response)
  end

  def url_object(url = nil)
    obj = mock('url_object')
    url ||= 'http://www.google.de'
    obj.stubs(:url).returns(url)
    obj
  end

end

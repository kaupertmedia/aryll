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

  test "should instantiate with optional configuration hash" do
    assert defined?(Kauperts::LinkChecker::Configuration)

    obj = checker.new(url_object)
    assert_respond_to obj, :configuration

    assert_respond_to obj.configuration, :ignore_trailing_slash_redirects
    assert !obj.configuration.ignore_trailing_slash_redirects

    obj = checker.new(url_object, :ignore_trailing_slash_redirects => true)

    assert_respond_to obj.configuration, :ignore_trailing_slash_redirects
    assert_equal true, obj.configuration.ignore_trailing_slash_redirects
  end

  test "should expose object" do
    obj = checker.new(url_object)
    assert_respond_to obj, :object
  end

  test "should have check! method" do
    obj = checker.new(url_object)
    assert_respond_to obj, :check!
    assert_equal checker.method(:check!).arity, -2
  end

  test "should return status array with 200" do
    stub_net_http!
    url = url_object
    obj = checker.new(url)
    a = obj.check!
    assert_equal "200", obj.check!
  end

  test "should ignore permanent redirects with trailing slash only if told so" do
    url = url_object("http://www.example.com/foo")
    location = url.url + "/"
    stub_net_http_redirect!("301", location)

    obj = checker.new(url)
    obj.check!
    assert_equal false, obj.ok?

    obj = checker.new(url, :ignore_trailing_slash_redirects => true)
    obj.check!
    assert_equal true, obj.ok?
  end

  test "should return status array with 404" do
    stub_net_http!("404")
    url = url_object
    obj = checker.new(url)
    assert_equal "404", obj.check!
  end

  test "should handle time out exceptions" do
    stub_net_http_error!(Timeout::Error, "Takes way too long")
    url = url_object
    obj = checker.new(url)
    assert_nothing_raised do
      status = obj.check!
      assert_kind_of String, status
      assert_match /Timeout (.+)/, status
    end
  end

  test "should handle generic network problem" do
    class GenericNetworkException < Exception; end
    stub_net_http_error!(GenericNetworkException, "Somehow broken")
    url = url_object
    obj = checker.new(url)
    assert_nothing_raised do
      status = obj.check!
      assert_kind_of String, status
      assert_match /Generic network error (.+)/, status
    end
  end

  test "should handle domain with umlauts" do
    SimpleIDN.expects(:to_ascii).returns('www.xn--trotzkpfchen-9ib.de').at_least(1)
    stub_net_http!
    url = url_object('http://www.trotzköpfchen.de')
    obj = checker.new(url)
    assert_equal "200", obj.check!
  end

  test "should handle ssl protocol" do
    stub_net_https!
    url = url_object(nil, "https")
    obj = checker.new(url)
    assert_equal "200", obj.check!
  end

  test "should have status" do
    stub_net_http!
    url = url_object
    obj = checker.new(url)
    assert_respond_to obj, :status
    assert_nil obj.status
    obj.check!
    assert_not_nil obj.status
  end

  test "should have ok? method" do
    stub_net_http!
    url = url_object
    obj = checker.new(url)
    assert_respond_to obj, :ok?
    assert !obj.ok?
    obj.check!
    assert obj.ok?
  end

  test "should check directly when called from class" do
    stub_net_http!
    url = url_object
    assert_respond_to checker, :check!
    assert_raises ArgumentError do
      checker.check!
    end
    assert_kind_of checker, checker.check!(url)
  end

  test "should support I18n message for timeout error" do
    I18n.expects(:t).with(:"kauperts.link_checker.errors.timeout", :default => "Timeout").returns('Zeitüberschreitung')
    stub_net_http_error!(Timeout::Error, "Dauert zu lange")
    url = url_object
    assert_match /Zeitüberschreitung (.+)/, checker.check!(url).status
  end

  test "should support I18n message for generic network error" do
    I18n.expects(:t).with(:"kauperts.link_checker.errors.generic_network", :default => "Generic network error").returns('Netzwerkfehler')
    class GenericNetworkException < Exception; end
    stub_net_http_error!(GenericNetworkException, "Irgendwie kaputt")
    url = url_object
    assert_match /Netzwerkfehler (.+)/, checker.check!(url).status
  end

  test "should return redirection url" do
    stub_net_http_redirect!
    url = url_object
    assert_match /auenland.de/, checker.check!(url).status
  end

  test "should support I18n message for 301 permanent redirects" do
    I18n.expects(:t).with(:"kauperts.link_checker.status.redirect_permanently", :default => "Moved permanently").returns('Umgezogen')
    location = "http://auenland.de"
    stub_net_http_redirect!(301, location)
    url = url_object
    assert_match /Umgezogen \(#{location}\)/, checker.check!(url).status
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

  def stub_net_https!(return_code = "200")
    return_code = return_code.to_s
    mock_response = mock('sslresponse')
    mock_response.stubs(:code).returns(return_code)
    Net::HTTP.any_instance.stubs(:start).returns(mock_response)
  end

  def stub_net_http_error!(exception, message)
    Net::HTTP.stubs(:get_response).raises(exception, message)
  end

  def stub_net_http_redirect!(return_code = '301', location ="http://auenland.de")
    return_code = return_code.to_s
    mock_response = {'location' => location}
    mock_response.stubs(:code).returns(return_code)
    Net::HTTP.stubs(:get_response).returns(mock_response)
  end

  def url_object(url = nil, protocol = 'http')
    obj = mock('url_object')
    url ||= "#{protocol}://www.google.com"
    obj.stubs(:url).returns(url)
    obj
  end

end

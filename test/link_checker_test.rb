# encoding: utf-8
require 'test_helper'

describe Kauperts::LinkChecker do

  def url_object(url = nil, protocol = 'http')
    obj = mock('url_object')
    url ||= "#{protocol}://www.google.com"
    obj.stubs(:url).returns(url)
    obj
  end

  subject { described_class.new url_object }

  describe 'its constructor' do
    let(:url_object) { Class.new { attr_reader :url }.new }

    it 'accepts objects responding to "url"' do
      described_class.new(url_object).must_be_instance_of described_class
    end

    it 'raises an ArgumentError if object does not respond to "url"' do
      -> { described_class.new(Object.new) }.must_raise ArgumentError
    end

    it 'sets the url object' do
      subject.object.must_equal url_object
    end
  end

  describe '.check!' do
    it { described_class.method(:check!).arity.must_equal(-2) }

    it 'creates an instance and calls #check! on it' do
      described_class.any_instance.expects(:check!)
      described_class.check! url_object
    end

    it 'returns a link checker instance' do
      described_class.check!(url_object).must_be_instance_of described_class
    end
  end

  describe '#check!' do
    it "returns a '200' status" do
      stub_net_http!
      subject.check!.must_equal '200'
    end

    it "returns a '404' status" do
      stub_net_http!("404")
      subject.check!.must_equal '404'
    end

    describe 'with configuration options' do

      describe 'for trailing slashes' do
        let(:url_object) do
          Class.new { def url; 'http://www.example.com/foo' end }.new
        end

        before { stub_net_http_redirect!("301", url_object.url + '/') }

        it 'considers trailing slashes for redirects not ok by default' do
          subject.check!
          subject.ok?.must_equal false
        end

        it 'ignores permanent redirects with trailing slash' do
          subject = described_class.new(url_object, ignore_trailing_slash_redirects: true )
          subject.check!
          subject.ok?.must_equal true
        end
      end

      describe 'for temporary redirects (302)' do
        before do
          stub_net_http_redirect!("302")
        end

        it 'considers temporary redirects not ok by default' do
          subject.check!
          subject.ok?.must_equal false
        end

        it 'ignores temporary redirects' do
          subject = described_class.new(url_object, ignore_302_redirects: true)
          subject.check!
          subject.ok?.must_equal true
        end
      end

    end

  end

  def described_class
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
end

class LinkCheckerTest < ActiveSupport::TestCase

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

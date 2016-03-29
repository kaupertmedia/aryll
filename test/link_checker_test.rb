require 'test_helper'

describe Aryll::LinkChecker do

  let(:url) do
    'http://www.example.com'
  end

  subject { described_class.new url }

  let(:translation) { {} }

  before do
    I18n.backend.store_translations I18n.locale, translation
  end

  after { I18n.backend.reload! }

  describe 'the class-level configuration defaults' do

    [:ignore_trailing_slash_redirects, :ignore_302_redirects].each do |configuration|
      describe ".#{configuration}" do
        it "has a getter and setter" do
          described_class.must_respond_to configuration
          described_class.must_respond_to "#{configuration}="
        end
      end
    end

    describe '.configure' do
      [:ignore_trailing_slash_redirects, :ignore_302_redirects].each do |configuration|
        it "changes the value for #{configuration}" do
          config_val = described_class.send configuration
          proc {
            described_class.configure do |config|
              config.send "#{configuration}=", 'foo'
            end
          }.must_change -> { described_class.send(configuration) }
          described_class.send "#{configuration}=", config_val
        end
      end
    end

  end

  describe 'its constructor' do
    it 'sets the url object' do
      subject.url.must_equal url
    end
  end

  describe '.check!' do
    it { described_class.method(:check!).arity.must_equal(-2) }

    let(:request_stub) { stub_net_http! }

    before { request_stub }

    it 'returns a link checker instance' do
      subject = described_class.check!(url)
      subject.must_be_instance_of described_class
      assert_requested request_stub
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

    describe 'with SSL' do
      let(:url) do
        'https://www.example.com/'
      end

      it "returns a '200' status" do
        stub_net_http! protocol: 'https'
        subject.check!.must_equal '200'
      end
    end

    describe 'with configuration options' do
      describe 'for trailing slashes' do
        before { stub_net_http_redirect!("301", location: url + '/') }

        it 'considers trailing slashes for redirects not ok by default' do
          subject.check!
          subject.ok?.must_equal false
        end

        it 'ignores permanent redirects with trailing slash' do
          subject = described_class.new(url, ignore_trailing_slash_redirects: true )
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
          subject = described_class.new(url, ignore_302_redirects: true)
          subject.check!
          subject.ok?.must_equal true
        end
      end
    end

    describe 'with timeout errors' do
      before do
        stub_request(:any, 'www.example.com').to_timeout
      end

      it 'handles timeouts' do
        subject.check!
        subject.status.must_match(/Timeout .+/)
      end

      describe 'with I18n' do
        let(:translation) do
          { kauperts: { link_checker: { errors: { timeout: "Zeitüberschreitung" } } } }
        end

        it 'translates the error message' do
          subject.check!
          subject.status.must_match(/Zeitüberschreitung .+/)
        end
      end
    end

    describe 'with a unrecognized network error' do
      let(:generic_error) { Class.new(StandardError) }

      before do
        stub_request(:any, 'www.example.com').to_raise generic_error
      end

      it 'handles generic network problem' do
        subject.check!
        subject.status.must_match(/Generic network error .+/)
      end

      describe 'with I18n' do
        let(:translation) do
          { kauperts: { link_checker: { errors: { generic_network: "Netzwerkfehler" } } } }
        end

        it 'translates the error message' do
          subject.check!
          subject.status.must_match(/Netzwerkfehler .+/)
        end
      end
    end

    describe 'with IDN domains' do
      let(:url) do
        'http://www.trotzköpfchen.de'
      end

      before do
        stub_net_http!(host: 'www.xn--trotzkpfchen-9ib.de')
      end

      it 'handles domain with umlauts' do
        subject.check!.must_equal '200'
        subject.ok?.must_equal true
      end
    end

  end

  describe '#status' do
    describe 'with a permanent redirect' do
      before do
        stub_net_http_redirect!("301")
        subject.check!
      end

      it 'returns the redirection url' do
        subject.status.must_equal 'Moved permanently (http://auenland.de)'
      end

      describe 'with I18n' do
        let(:translation) do
          { kauperts: { link_checker: { status: { redirect_permanently: "Umgezogen" } } } }
        end

        it 'translates the status' do
          subject.status.must_match(/Umgezogen \(http:.+/)
        end
      end
    end

  end

  def described_class
    Aryll::LinkChecker
  end

  def stub_net_http!(return_code = "200", host: 'www.example.com', path: '/', protocol: 'http')
    stub_request(:get, "#{protocol}://#{host}#{path}").to_return(status: return_code.to_i)
  end

  def stub_net_http_redirect!(return_code = '301', location: "http://auenland.de")
    stub_request(:get, "http://www.example.com").to_return(
      status: return_code.to_i,
      headers: { 'Location' => location }
    )
  end
end

require 'test_helper'

describe Aryll do

  let(:url) do
    'http://www.example.com'
  end

  describe '.check!' do
    it { described_class.method(:check!).arity.must_equal(-2) }

    let(:request_stub) { stub_net_http! }

    before { request_stub }

    it 'returns a link checker instance' do
      subject = described_class.check!(url)
      subject.must_be_instance_of Aryll::LinkChecker
      assert_requested request_stub
    end
  end

  def described_class
    Aryll
  end

  def stub_net_http!(return_code = "200", host: 'www.example.com', path: '/', protocol: 'http')
    stub_request(:get, "#{protocol}://#{host}#{path}").to_return(status: return_code.to_i)
  end
end

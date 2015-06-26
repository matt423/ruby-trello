require 'spec_helper'

describe Trello::Configuration do
  let(:configuration) { Trello::Configuration.new }

  it 'has a consumer_key attribute' do
    configuration.consumer_key = 'consumer_key'
    expect(configuration.consumer_key).to eq('consumer_key')
  end

  it 'has a consumer_secret attribute' do
    configuration.consumer_secret = 'consumer_secret'
    expect(configuration.consumer_secret).to eq('consumer_secret')
  end

  it 'has a oauth_token attribute' do
    configuration.oauth_token = 'oauth_token'
    expect(configuration.oauth_token).to eq('oauth_token')
  end

  it 'has a oauth_token_secret attribute' do
    configuration.oauth_token_secret = 'oauth_token_secret'
    expect(configuration.oauth_token_secret).to eq('oauth_token_secret')
  end

  it 'has a developer public key attribute' do
    configuration.developer_public_key = 'developer_public_key'
    expect(configuration.developer_public_key).to eq('developer_public_key')
  end

  it 'has a member token attribute' do
    configuration.member_token = 'member_token'
    expect(configuration.member_token).to eq('member_token')
  end

  it 'has a callback (for oauth)' do
    callback = -> { 'foobar' }
    configuration.callback = callback
    expect(configuration.callback.call).to eq('foobar')
  end

  it 'has a return_url' do
    configuration.return_url = 'http://www.example.com/callback'
    expect(configuration.return_url).to eq('http://www.example.com/callback')
  end

  describe 'initialize' do
    it 'sets key attributes provided as a hash' do
      configuration = Trello::Configuration.new(
        consumer_key: 'consumer_key',
        consumer_secret: 'consumer_secret',
        oauth_token: 'oauth_token',
        oauth_token_secret: 'oauth_token_secret'
      )
      expect(configuration.consumer_key).to eq('consumer_key')
      expect(configuration.consumer_secret).to eq('consumer_secret')
      expect(configuration.oauth_token).to eq('oauth_token')
      expect(configuration.oauth_token_secret).to eq('oauth_token_secret')
    end
  end

  describe '#credentials' do
    let(:configuration) { Trello::Configuration.new(attributes) }

    it 'returns an empty if no attributes specified' do
      expect(Trello::Configuration.new({}).credentials).to eq({})
    end

    it 'returns an empty if attributes incomplete' do
      expect(Trello::Configuration.new(consumer_key: 'consumer_key').credentials).to eq({})
    end

    it 'returns a hash of oauth attributes' do
      configuration = Trello::Configuration.new(
        consumer_key: 'consumer_key',
        consumer_secret: 'consumer_secret',
        oauth_token: 'oauth_token',
        oauth_token_secret: 'oauth_token_secret'
      )
      expect(configuration.credentials).to eq(
        consumer_key: 'consumer_key',
        consumer_secret: 'consumer_secret',
        oauth_token: 'oauth_token',
        oauth_token_secret: 'oauth_token_secret'
      )
    end

    it 'includes callback and return url if given' do
      configuration = Trello::Configuration.new(
        consumer_key: 'consumer_key',
        consumer_secret: 'consumer_secret',
        return_url: 'http://example.com',
        callback: 'callback'
      )
      expect(configuration.credentials).to eq(
        consumer_key: 'consumer_key',
        consumer_secret: 'consumer_secret',
        return_url: 'http://example.com',
        callback: 'callback'
      )
    end

    it 'returns a hash of basic auth policy attributes' do
      configuration = Trello::Configuration.new(
        developer_public_key: 'developer_public_key',
        member_token: 'member_token'
      )
      expect(configuration.credentials).to eq(
        developer_public_key: 'developer_public_key',
        member_token: 'member_token'
      )
    end
  end
end

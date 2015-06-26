# Specs covering the members namespace in the Trello API

require 'spec_helper'

module Trello
  describe Member do
    include Helpers

    let(:member) { client.find(:member, 'abcdef123456789012345678') }
    let(:client) { Client.new }

    before(:each) do
      allow(client).to receive(:get).with('/members/abcdef123456789012345678', {}).and_return user_payload
    end

    context 'finding' do
      let(:client) { Trello.client }

      it 'delegates to Trello.client#find' do
        expect(client).to receive(:find).with(:member, 'abcdef123456789012345678', {})
        Member.find('abcdef123456789012345678')
      end

      it 'is equivalent to client#find' do
        expect(Member.find('abcdef123456789012345678')).to eq(member)
      end
    end

    context 'actions' do
      it 'retrieves a list of actions', refactor: true do
        allow(client).to receive(:get).with('/members/abcdef123456789012345678/actions', { filter: :all }).and_return actions_payload
        expect(member.actions.count).to be > 0
      end
    end

    context 'boards' do
      it 'has a list of boards' do
        allow(client).to receive(:get).with('/members/abcdef123456789012345678/boards', { filter: :all }).and_return boards_payload
        boards = member.boards
        expect(boards.count).to be > 0
      end
    end

    context 'cards' do
      it 'has a list of cards' do
        allow(client).to receive(:get).with('/members/abcdef123456789012345678/cards', { filter: :open }).and_return cards_payload
        cards = member.cards
        expect(cards.count).to be > 0
      end
    end

    context 'organizations' do
      it 'has a list of organizations' do
        allow(client).to receive(:get).with('/members/abcdef123456789012345678/organizations', { filter: :all }).and_return orgs_payload
        orgs = member.organizations
        expect(orgs.count).to be > 0
      end
    end

    context 'notifications' do
      it 'has a list of notifications' do
        allow(client).to receive(:get).with('/members/abcdef123456789012345678/notifications', {}).and_return '[' << notification_payload << ']'
        expect(member.notifications.count).to be 1
      end
    end

    context 'personal' do
      it 'gets the members bio' do
        expect(member.bio).to eq(user_details['bio'])
      end

      it 'gets the full name' do
        expect(member.full_name).to eq(user_details['fullName'])
      end

      it 'gets the avatar id' do
        expect(member.avatar_id).to eq(user_details['avatarHash'])
      end

      it 'returns a valid url for the avatar' do
        expect(member.avatar_url(size: :large)).to eq('https://trello-avatars.s3.amazonaws.com/abcdef1234567890abcdef1234567890/170.png')
        expect(member.avatar_url(size: :small)).to eq('https://trello-avatars.s3.amazonaws.com/abcdef1234567890abcdef1234567890/30.png')
      end

      it 'gets the url' do
        expect(member.url).to eq(user_details['url'])
      end

      it 'gets the username' do
        expect(member.username).to eq(user_details['username'])
      end

      it 'gets the email' do
        expect(member.email).to eq(user_details['email'])
      end

      it 'gets the initials' do
        expect(member.initials).to eq(user_details['initials'])
      end
    end

    context 'modification' do
      it 'lets us know a field has changed without committing it' do
        expect(member.changed?).to be(false)
        member.bio = 'New and amazing'
        expect(member.changed?).to be(true)
      end

      it 'does not understand the #id= method' do
        expect { member.id = '42' }.to raise_error NoMethodError
      end
    end
  end
end

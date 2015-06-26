require 'spec_helper'

module Trello
  describe Action do
    include Helpers

    let(:action) { client.find(:action, '4ee2482134a81a757a08af47') }
    let(:client) { Client.new }

    before(:each) do
      allow(client).to receive(:get).with('/actions/4ee2482134a81a757a08af47', {}).
        and_return JSON.generate(actions_details.first)
    end

    context 'finding' do
      let(:client) { Trello.client }

      it 'delegates to Trello.client#find' do
        expect(client).to receive(:find).with(:action, '4ee2482134a81a757a08af47', {})
        Action.find('4ee2482134a81a757a08af47')
      end

      it 'is equivalent to client#find' do
        expect(Action.find('4ee2482134a81a757a08af47')).to eq(action)
      end
    end

    context 'search' do
      let(:client) { Trello.client }

      it "should search and get back a card object" do
        expect(client).to receive(:get).with("/search/", { query: "something"}).and_return(JSON.generate({ "cards" => cards_details }))
        expect(Action.search("something")).to eq({ "cards" => cards_details.jsoned_into(Card) })
      end
    end

    context 'fields' do
      let(:detail) { actions_details.first }

      it 'gets its id' do
        expect(action.id).to eq(detail['id'])
      end

      it 'gets its type' do
        expect(action.type).to eq(detail['type'])
      end

      it 'has the same data' do
        expect(action.data).to eq(detail['data'])
      end

      it 'gets the date' do
        expect(action.date.utc.iso8601).to eq(detail['date'])
      end
    end

    context 'boards' do
      it 'has a board' do
        allow(client).to receive(:get).with('/actions/4ee2482134a81a757a08af47/board').
          and_return JSON.generate(boards_details.first)

        expect(action.board).not_to be_nil
      end
    end

    context 'card' do
      it 'has a card' do
        allow(client).to receive(:get).with('/actions/4ee2482134a81a757a08af47/card').
          and_return JSON.generate(cards_details.first)

        expect(action.card).not_to be_nil
      end
    end

    context 'list' do
      it 'has a list of lists' do
        allow(client).to receive(:get).with('/actions/4ee2482134a81a757a08af47/list').
          and_return JSON.generate(lists_details.first)

        expect(action.list).not_to be_nil
      end
    end

    context 'member creator' do
      it 'knows its member creator' do
        allow(client).to receive(:get).with('/members/abcdef123456789123456789', {}).and_return user_payload

        expect(action.member_creator).not_to be_nil
      end
    end
  end
end

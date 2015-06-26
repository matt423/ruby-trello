require 'spec_helper'

module Trello
  describe Item do
    before(:all) do
      @detail = {
        'id'   => 'abcdef123456789123456789',
        'name' => 'test item',
        'type' => 'check',
        'state' => 'complete',
        'pos' => 0
      }

      @item = Item.new(@detail)
    end

    it 'gets its id' do
      expect(@item.id).to eq(@detail['id'])
    end

    it 'gets its name' do
      expect(@item.name).to eq(@detail['name'])
    end

    it 'knows its type' do
      expect(@item.type).to eq(@detail['type'])
    end

    it 'knows its state' do
      expect(@item.state).to eq(@detail['state'])
    end

    it 'knows its pos' do
      expect(@item.pos).to eq(@detail['pos'])
    end
  end
end

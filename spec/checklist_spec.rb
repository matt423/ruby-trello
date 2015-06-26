require 'spec_helper'

module Trello
  describe Checklist do
    include Helpers

    let(:checklist) { client.find(:checklist, 'abcdef123456789123456789') }
    let(:client) { Client.new }

    before(:each) do
      allow(client).to receive(:get).with("/checklists/abcdef123456789123456789", {}).
          and_return JSON.generate(checklists_details.first)
    end

    context "finding" do
      let(:client) { Trello.client }

      it "delegates to Trello.client#find" do
        expect(client).to receive(:find).with(:checklist, 'abcdef123456789123456789', {})
        Checklist.find('abcdef123456789123456789')
      end

      it "is equivalent to client#find" do
        expect(Checklist.find('abcdef123456789123456789')).to eq(checklist)
      end
    end

    context "creating" do
      let(:client) { Trello.client }

      it 'creates a new record and saves it on Trello', refactor: true do
        payload = {
            name: 'Test Checklist',
            desc: '',
        }

        result = JSON.generate(checklists_details.first.merge(payload.merge(idBoard: boards_details.first['id'])))

        expected_payload = {name: "Test Checklist", idBoard: "abcdef123456789123456789"}

        expect(client).to receive(:post).with("/checklists", expected_payload).and_return result

        checklist = Checklist.create(checklists_details.first.merge(payload.merge(board_id: boards_details.first['id'])))

        expect(checklist.class).to be Checklist
      end
    end

    context "deleting" do
      let(:client) { Trello.client }

      it "deletes a checklist" do
        expect(client).to receive(:delete).with("/checklists/#{checklist.id}")
        checklist.delete
      end

      it "deletes a checklist item" do
        item_id = checklist.check_items.first.last
        expect(client).to receive(:delete).with("/checklists/#{checklist.id}/checkItems/#{item_id}")
        checklist.delete_checklist_item(item_id)
      end
    end

    context "updating" do
      it "updating name does a put on the correct resource with the correct value" do
        expected_new_name = "xxx"
        expected_resource = "/checklists/abcdef123456789123456789"
        payload = {
            name: expected_new_name,
            pos: checklist.position
        }

        result = JSON.generate(checklists_details.first)
        expect(client).to receive(:put).once.with(expected_resource, payload).and_return result

        checklist.name = expected_new_name
        checklist.save
      end

      it "updating position does a put on the correct resource with the correct value" do
        expected_new_position = 33
        expected_resource = "/checklists/abcdef123456789123456789"
        payload = {
            name: checklist.name,
            pos: expected_new_position
        }

        result = JSON.generate(checklists_details.first)
        expect(client).to receive(:put).once.with(expected_resource, payload).and_return result

        checklist.position = expected_new_position
        checklist.save
      end

      it "adds an item" do
        expected_item_name = "item1"
        expected_checked = true
        expected_pos = 9999
        payload = {
            name: expected_item_name,
            checked: expected_checked,
            pos: expected_pos
        }
        result_hash = {
            name: expected_item_name,
            state: expected_checked ? 'complete' : 'incomplete',
            pos: expected_pos
        }
        result = JSON.generate(result_hash)
        expect(client).to receive(:post).once.with("/checklists/abcdef123456789123456789/checkItems", payload).and_return result

        checklist.add_item(expected_item_name, expected_checked, expected_pos)
      end
    end

    context "board" do
      it "has a board" do
        allow(client).to receive(:get).with("/boards/abcdef123456789123456789").and_return JSON.generate(boards_details.first)
        expect(checklist.board).not_to be_nil
      end
    end

    context "list" do
      it 'has a list' do
        allow(client).to receive(:get).with("/lists/abcdef123456789123456789", {}).and_return JSON.generate(lists_details.first)
        expect(checklist.list).not_to be_nil
      end
    end
  end
end

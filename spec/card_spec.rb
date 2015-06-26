require 'spec_helper'

module Trello
  describe Card do
    include Helpers

    let(:card) { client.find(:card, 'abcdef123456789123456789') }
    let(:client) { Client.new }

    before(:each) do
      allow(client).to receive(:get).with("/cards/abcdef123456789123456789", {}).
        and_return JSON.generate(cards_details.first)
    end

    context "finding" do
      let(:client) { Trello.client }

      it "delegates to Trello.client#find" do
        expect(client).to receive(:find).with(:card, 'abcdef123456789123456789', {})
        Card.find('abcdef123456789123456789')
      end

      it "is equivalent to client#find" do
        expect(Card.find('abcdef123456789123456789')).to eq(card)
      end
    end

    context "creating" do
      let(:client) { Trello.client }

      it "creates a new record" do
        card = Card.new(cards_details.first)
        expect(card).to be_valid
      end

      it 'must not be valid if not given a name' do
        card = Card.new('idList' => lists_details.first['id'])
        expect(card).not_to be_valid
      end

      it 'must not be valid if not given a list id' do
        card = Card.new('name' => lists_details.first['name'])
        expect(card).not_to be_valid
      end

      it 'creates a new record and saves it on Trello', refactor: true do
        payload = {
          name: 'Test Card',
          desc: nil,
        }

        result = JSON.generate(cards_details.first.merge(payload.merge(idList: lists_details.first['id'])))

        expected_payload = {name: "Test Card", desc: nil, idList: "abcdef123456789123456789",
                            idMembers: nil, labels: nil, pos: nil }

        expect(client).to receive(:post).with("/cards", expected_payload).and_return result

        card = Card.create(cards_details.first.merge(payload.merge(list_id: lists_details.first['id'])))

        expect(card.class).to be Card
      end
    end

    context "updating" do
      it "updating name does a put on the correct resource with the correct value" do
        expected_new_name = "xxx"

        payload = {
          name: expected_new_name,
        }

        expect(client).to receive(:put).once.with("/cards/abcdef123456789123456789", payload)

        card.name = expected_new_name
        card.save
      end
    end

    context "deleting" do
      it "deletes the card" do
        expect(client).to receive(:delete).with("/cards/#{card.id}")
        card.delete
      end
    end

    context "fields" do
      it "gets its id" do
        expect(card.id).not_to be_nil
      end

      it "gets its short id" do
        expect(card.short_id).not_to be_nil
      end

      it "gets its name" do
        expect(card.name).not_to be_nil
      end

      it "gets its description" do
        expect(card.desc).not_to be_nil
      end

      it "knows if it is open or closed" do
        expect(card.closed).not_to be_nil
      end

      it "gets its url" do
        expect(card.url).not_to be_nil
      end

      it "gets its short url" do
        expect(card.short_url).not_to be_nil
      end

      it "gets its last active date" do
        expect(card.last_activity_date).not_to be_nil
      end

      it "gets its cover image id" do
        expect(card.cover_image_id).not_to be_nil
      end

      it "gets its pos" do
        expect(card.pos).not_to be_nil
      end
    end

    context "actions" do
      it "asks for all actions by default" do
        allow(client).to receive(:get).with("/cards/abcdef123456789123456789/actions", { filter: :all }).and_return actions_payload
        expect(card.actions.count).to be > 0
      end

      it "allows overriding the filter" do
        allow(client).to receive(:get).with("/cards/abcdef123456789123456789/actions", { filter: :updateCard }).and_return actions_payload
        expect(card.actions(filter: :updateCard).count).to be > 0
      end
    end

    context "boards" do
      it "has a board" do
        allow(client).to receive(:get).with("/boards/abcdef123456789123456789", {}).and_return JSON.generate(boards_details.first)
        expect(card.board).not_to be_nil
      end
    end

    context "cover image" do
      it "has a cover image" do
        allow(client).to receive(:get).with("/attachments/abcdef123456789123456789", {}).and_return JSON.generate(attachments_details.first)
        expect(card.cover_image).not_to be_nil
      end
    end

    context "checklists" do
      before(:each) do
        allow(client).to receive(:get).with("/cards/abcdef123456789123456789/checklists", { filter: :all }).and_return checklists_payload
      end

      it "has a list of checklists" do
        expect(card.checklists.count).to be > 0
      end

      it "creates a new checklist for the card" do
        expect(client).to receive(:post).with("/cards/abcdef123456789123456789/checklists", name: "new checklist")
        card.create_new_checklist("new checklist")
      end
    end

    context "list" do
      it 'has a list' do
        allow(client).to receive(:get).with("/lists/abcdef123456789123456789", {}).and_return JSON.generate(lists_details.first)
        expect(card.list).not_to be_nil
      end

      it 'can be moved to another list' do
        other_list = double(id: '987654321987654321fedcba')
        payload = {value: other_list.id}
        expect(client).to receive(:put).with("/cards/abcdef123456789123456789/idList", payload)
        card.move_to_list(other_list)
      end

      it 'should not be moved if new list is identical to old list' do
        other_list = double(id: 'abcdef123456789123456789')
        payload = { value: other_list.id }
        expect(client).not_to receive(:put)
        card.move_to_list(other_list)
      end

      it "should accept a string for moving a card to list" do
        payload = { value: "12345678"}
        expect(client).to receive(:put).with("/cards/abcdef123456789123456789/idList", payload)
        card.move_to_list("12345678")
      end

      it 'can be moved to another board' do
        other_board = double(id: '987654321987654321fedcba')
        payload = {value: other_board.id}
        expect(client).to receive(:put).with("/cards/abcdef123456789123456789/idBoard", payload)
        card.move_to_board(other_board)
      end

      it 'can be moved to a list on another board' do
        other_board = double(id: '987654321987654321fedcba')
        other_list = double(id: '987654321987654321aalist')
        payload = {value: other_board.id, idList: other_list.id}
        expect(client).to receive(:put).with("/cards/abcdef123456789123456789/idBoard", payload)
        card.move_to_board(other_board, other_list)
      end

      it 'should not be moved if new board is identical with old board', focus: true do
        other_board = double(id: 'abcdef123456789123456789')
        expect(client).not_to receive(:put)
        card.move_to_board(other_board)
      end
    end

    context "members" do
      it "has a list of members" do
        allow(client).to receive(:get).with("/boards/abcdef123456789123456789", {}).and_return JSON.generate(boards_details.first)
        allow(client).to receive(:get).with("/members/abcdef123456789123456789").and_return user_payload

        expect(card.board).not_to be_nil
        expect(card.members).not_to be_nil
      end

      it "allows a member to be added to a card" do
        new_member = double(id: '4ee7df3ce582acdec80000b2')
        payload = {
          value: new_member.id
        }
        expect(client).to receive(:post).with("/cards/abcdef123456789123456789/members", payload)
        card.add_member(new_member)
      end

      it "allows a member to be removed from a card" do
        existing_member = double(id: '4ee7df3ce582acdec80000b2')
        expect(client).to receive(:delete).with("/cards/abcdef123456789123456789/members/#{existing_member.id}")
        card.remove_member(existing_member)
      end
    end

    context "comments" do
      it "posts a comment" do
        expect(client).to receive(:post).
          with("/cards/abcdef123456789123456789/actions/comments", { text: 'testing' }).
          and_return JSON.generate(boards_details.first)

        card.add_comment "testing"
      end
    end

    context "labels" do
      it "can retrieve labels" do
        allow(client).to receive(:get).with("/cards/abcdef123456789123456789/labels").
          and_return label_payload
        labels = card.labels
        expect(labels.size).to  eq(4)

        expect(labels[0].color).to  eq('yellow')
        expect(labels[0].id).to  eq('abcdef123456789123456789')
        expect(labels[0].board_id).to  eq('abcdef123456789123456789')
        expect(labels[0].name).to  eq('iOS')
        expect(labels[0].uses).to  eq(3)

        expect(labels[1].color).to  eq('purple')
        expect(labels[1].id).to  eq('abcdef123456789123456789')
        expect(labels[1].board_id).to  eq('abcdef123456789123456789')
        expect(labels[1].name).to  eq('Issue or bug')
        expect(labels[1].uses).to  eq(1)
      end

      it "can add a label" do
        allow(client).to receive(:post).with("/cards/abcdef123456789123456789/labels", { value: 'green' }).
          and_return "not important"
        card.add_label('green')
        expect(card.errors).to be_empty
      end

      it "can remove a label" do
        allow(client).to receive(:delete).with("/cards/abcdef123456789123456789/labels/green").
          and_return "not important"
        card.remove_label('green')
        expect(card.errors).to be_empty
      end

      it "can remove a label instance" do
        expect(client).to receive(:delete).once.with("/cards/abcdef123456789123456789/idLabels/abcdef123456789123456789")
        label = Label.new(label_details.first)
        card.remove_label(label)
      end

      it "can add a label of any valid color" do
        %w(green yellow orange red purple blue sky lime pink black).each do |color|
          allow(client).to receive(:post).with("/cards/abcdef123456789123456789/labels", { :value => color }).
            and_return "not important"
          card.add_label(color)
          expect(card.errors).to be_empty
        end
      end

      it "can add a label instance" do
        expect(client).to receive(:post).once.with("/cards/abcdef123456789123456789/idLabels", {:value => "abcdef123456789123456789"})
        label = Label.new(label_details.first)
        card.add_label label
      end

      it "throws an error when trying to add a label with an unknown colour" do
        allow(client).to receive(:post).with("/cards/abcdef123456789123456789/labels", { value: 'green' }).
          and_return "not important"
        card.add_label('mauve')
        expect(card.errors.full_messages.to_sentence).to eq("Label colour 'mauve' does not exist")
      end

      it "throws an error when trying to remove a label with an unknown colour" do
        allow(client).to receive(:delete).with("/cards/abcdef123456789123456789/labels/mauve").
          and_return "not important"
        card.remove_label('mauve')
        expect(card.errors.full_messages.to_sentence).to eq("Label colour 'mauve' does not exist")
      end
    end

    context "attachments" do
      it "can add an attachment" do
        f = File.new('spec/list_spec.rb', 'r')
        allow(client).to receive(:get).with("/cards/abcdef123456789123456789/attachments").and_return attachments_payload
        allow(client).to receive(:post).with("/cards/abcdef123456789123456789/attachments",
              { file: f, name: ''  }).
              and_return "not important"

        card.add_attachment(f)

        expect(card.errors).to be_empty
      end

      it "can list the existing attachments with correct fields" do
        allow(client).to receive(:get).with("/boards/abcdef123456789123456789", {}).and_return JSON.generate(boards_details.first)
        allow(client).to receive(:get).with("/cards/abcdef123456789123456789/attachments").and_return attachments_payload

        expect(card.board).not_to be_nil
        expect(card.attachments).not_to be_nil
        first_attachment = card.attachments.first
        expect(first_attachment.id).to eq(attachments_details[0]["id"])
        expect(first_attachment.name).to eq(attachments_details[0]["name"])
        expect(first_attachment.url).to eq(attachments_details[0]["url"])
        expect(first_attachment.bytes).to eq(attachments_details[0]["bytes"])
        expect(first_attachment.member_id).to eq(attachments_details[0]["idMember"])
        expect(first_attachment.date).to eq(Time.parse(attachments_details[0]["date"]))
        expect(first_attachment.is_upload).to eq(attachments_details[0]["isUpload"])
        expect(first_attachment.mime_type).to eq(attachments_details[0]["mimeType"])
      end

      it "can remove an attachment" do
        allow(client).to receive(:delete).with("/cards/abcdef123456789123456789/attachments/abcdef123456789123456789").
          and_return "not important"
        allow(client).to receive(:get).with("/cards/abcdef123456789123456789/attachments").and_return attachments_payload

        card.remove_attachment(card.attachments.first)
        expect(card.errors).to be_empty
      end
    end

    describe "#closed?" do
      it "returns the closed attribute" do
        expect(card.closed?).to be(false)
      end
    end

    describe "#close" do
      it "updates the close attribute to true" do
        card.close
        expect(card.closed).to be(true)
      end
    end

    describe "#close!" do
      it "updates the close attribute to true and saves the list" do
        payload = {
          closed: true,
        }

        expect(client).to receive(:put).once.with("/cards/abcdef123456789123456789", payload)

        card.close!
      end
    end

  end
end

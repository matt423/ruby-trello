require 'spec_helper'

module Trello
  describe Board do
    include Helpers

    let(:board) { client.find(:board, 'abcdef123456789123456789') }
    let(:client) { Client.new }
    let(:member) { Member.new(user_payload) }

    before(:each) do
      allow(client).to receive(:get).with("/boards/abcdef123456789123456789", {}).
        and_return JSON.generate(boards_details.first)
    end

    context "finding" do
      let(:client) { Trello.client }

      it "delegates to client#find" do
        expect(client).to receive(:find).with(:board, 'abcdef123456789123456789', {})
        Board.find('abcdef123456789123456789')
      end

      it "is equivalent to client#find" do
        expect(Board.find('abcdef123456789123456789')).to eq(board)
      end
    end

    context "self.all" do
      let(:client) { Trello.client }

      it "gets all boards" do
        allow(Member).to receive_message_chain(:find, :username).and_return "testuser"
        allow(client).to receive(:get).with("/members/testuser/boards").and_return boards_payload

        expected = Board.new(boards_details.first)
        expect(Board.all.first).to eq(expected)
      end
    end

    context "fields" do
      it "gets an id" do
        expect(board.id).not_to be_nil
      end

      it "gets a name" do
        expect(board.name).not_to be_nil
      end

      it "gets the description" do
        expect(board.description).not_to be_nil
      end

      it "knows if it is closed or open" do
        expect(board.closed?).not_to be_nil
      end

      it "knows if it is starred or not" do
        expect(board.starred?).not_to be_nil
      end

      it "gets its url" do
        expect(board.url).not_to be_nil
      end
    end

    context "actions" do
      it "has a list of actions" do
        allow(client).to receive(:get).with("/boards/abcdef123456789123456789/actions", {filter: :all}).
          and_return actions_payload

        expect(board.actions.count).to be > 0
      end
    end

    context "cards" do
      it "gets its list of cards" do
        allow(client).to receive(:get).with("/boards/abcdef123456789123456789/cards", { filter: :open }).
          and_return cards_payload

        expect(board.cards.count).to be > 0
      end
    end

    context "labels" do
      it "gets the specific labels for the board" do
        allow(client).to receive(:get).with("/boards/abcdef123456789123456789/labels").
          and_return label_payload
        labels = board.labels false
        expect(labels.count).to eq(4)


        expect(labels[2].color).to  eq('red')
        expect(labels[2].id).to  eq('abcdef123456789123456789')
        expect(labels[2].board_id).to  eq('abcdef123456789123456789')
        expect(labels[2].name).to  eq('deploy')
        expect(labels[2].uses).to  eq(2)

        expect(labels[3].color).to  eq('blue')
        expect(labels[3].id).to  eq('abcdef123456789123456789')
        expect(labels[3].board_id).to  eq('abcdef123456789123456789')
        expect(labels[3].name).to  eq('on hold')
        expect(labels[3].uses).to  eq(6)
      end

      it "gets the specific labels for the board" do
        allow(client).to receive(:get).with("/boards/abcdef123456789123456789/labelnames").
          and_return label_name_payload

        expect(board.labels.count).to eq(6)
      end
    end

    context "find_card" do
      it "gets a card" do
        allow(client).to receive(:get).with("/boards/abcdef123456789123456789/cards/1").
          and_return card_payload
        expect(board.find_card(1)).to be_a(Card)
      end
    end

    context "add_member" do
      it "adds a member to the board as a normal user (default)" do
        allow(client).to receive(:put).with("/boards/abcdef123456789123456789/members/id", type: :normal)
        board.add_member(member)
      end

      it "adds a member to the board as an admin" do
        allow(client).to receive(:put).with("/boards/abcdef123456789123456789/members/id", type: :admin)
        board.add_member(member, :admin)
      end
    end

    context "remove_member" do
      it "removes a member from the board" do
        allow(client).to receive(:delete).with("/boards/abcdef123456789123456789/members/id")
        board.remove_member(member)
      end
    end

    context "lists" do
      it "has a list of lists" do
        allow(client).to receive(:get).with("/boards/abcdef123456789123456789/lists", hash_including(filter: :open)).
          and_return lists_payload

        expect(board.has_lists?).to be true
      end
    end

    context "members" do
      it "has a list of members" do
        allow(client).to receive(:get).with("/boards/abcdef123456789123456789/members", hash_including(filter: :all)).
          and_return JSON.generate([user_details])

        expect(board.members.count).to be > 0
      end
    end

    context "organization" do
      it "belongs to an organization" do
        allow(client).to receive(:get).with("/organizations/abcdef123456789123456789", {}).
          and_return JSON.generate(orgs_details.first)

        expect(board.organization).not_to be_nil
      end
    end

    it "is not closed" do
      expect(board.closed?).not_to be(true)
    end

     it "is not starred" do
      expect(board.starred?).not_to be(true)
    end

    describe "#update_fields" do
      it "does not set any fields when the fields argument is empty" do
        expected = {
         'id' => "id",
         'name' => "name",
         'desc' => "desc",
         'closed' => false,
         'starred' => false,
         'url' => "url",
         'idOrganization' => "org_id"
        }

        board = Board.new(expected)
        board.client = client

        board.update_fields({})

        expected.each_pair do |key, value|
          if board.respond_to?(key)
            expect(board.send(key)).to eq(value)
          end
        end

        expect(board.description).to eq(expected['desc'])
        expect(board.organization_id).to eq(expected['idOrganization'])
      end

      it "sets any attributes supplied in the fields argument"
    end

    describe "#save" do
      let(:client) { Trello.client }

      let(:any_board_json) do
        JSON.generate(boards_details.first)
      end

      it "cannot currently save a new instance" do
        expect(client).not_to receive :put

        the_new_board = Board.new
        expect { the_new_board.save }.to raise_error(Trello::ConfigurationError)
      end

      it "puts all fields except id" do
        expected_fields = %w{ name description closed starred idOrganization}.map { |s| s.to_sym }

        expect(client).to receive(:put) do |anything, body|
          expect(body.keys).to match_array(expected_fields)
          any_board_json
        end

        the_new_board = Board.new 'id' => "xxx"
        the_new_board.save
      end

      it "mutates the current instance" do
        allow(client).to receive(:put).and_return any_board_json

        board = Board.new 'id' => "xxx"

        the_result_of_save = board.save

        expect(the_result_of_save).to equal board
      end

      it "uses the correct resource" do
        expected_resource_id = "xxx_board_id_xxx"

        expect(client).to receive(:put) do |path, anything|
          expect(path).to match(/#{expected_resource_id}\/$/)
          any_board_json
        end

        the_new_board = Board.new 'id' => expected_resource_id
        the_new_board.save
      end

      it "saves OR updates depending on whether or not it has an id set"
    end

    describe '#update!' do
      let(:client) { Trello.client }

      let(:any_board_json) do
        JSON.generate(boards_details.first)
      end

      it "puts basic attributes" do
        board = Board.new 'id' => "board_id"

        board.name        = "new name"
        board.description = "new description"
        board.closed      = true
        board.starred      = true

        expect(client).to receive(:put).with("/boards/#{board.id}/", {
          name: "new name",
          description: "new description",
          closed: true,
          starred: true,
          idOrganization: nil
        }).and_return any_board_json
        board.update!
      end
    end

    describe "Repository" do
      include Helpers

      let(:client) { Trello.client }

      let(:any_board_json) do
        JSON.generate(boards_details.first)
      end

      it "creates a new board with whatever attributes are supplied " do
        expected_attributes = { name: "Any new board name", description: "Any new board desription" }
        sent_attributes = { name: expected_attributes[:name], desc: expected_attributes[:description] }

        expect(client).to receive(:post).with("/boards", sent_attributes).and_return any_board_json

        Board.create expected_attributes
      end

      it "posts to the boards collection" do
        expect(client).to receive(:post).with("/boards", anything).and_return any_board_json

        Board.create xxx: ""
      end

      it "returns a board" do
        allow(client).to receive(:post).with("/boards", anything).and_return any_board_json

        the_new_board = Board.create xxx: ""
        expect(the_new_board).to be_a Board
      end

      it "at least name is required"
    end
  end
end

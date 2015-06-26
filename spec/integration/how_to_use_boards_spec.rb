require 'spec_helper'
require 'integration/integration_test'

describe "how to use boards", broken: true do
  include IntegrationTest

  context "given a valid access token" do
    before :all do
      OAuthPolicy.consumer_credential = OAuthCredential.new @developer_public_key, @developer_secret
      OAuthPolicy.token = OAuthCredential.new @access_token_key, @access_token_secret
      Container.set Trello::Authorization, "AuthPolicy", OAuthPolicy
    end

    after do
      if @new_board and false == @new_board.closed?
        @new_board.update_fields 'closed' => true
        @new_board.save
      end
    end

    it "can add a board" do
      @new_board = Board.create(name: "An example")
      expect(@new_board).not_to be_nil
      expect(@new_board.id).not_to be_nil
      expect(@new_board.name).to eq("An example")
      expect(@new_board).not_to be_closed
    end

    it "can read the welcome board" do
      welcome_board = Board.find @welcome_board
      expect(welcome_board.name).to be === "Welcome Board"
      expect(welcome_board.id).to be === @welcome_board
    end

    it "can close a board" do
      @new_board = Board.create(name: "[#{Time.now}, CLOSED] An example")

      @new_board.update_fields 'closed' => true
      @new_board.save

      expect(Board.find(@new_board.id)).to be_closed
    end

    it "can list all boards" do
      expect(Client.get("/members/me/boards/").json_into(Board)).to be_an Array
    end
  end
end

require "rails_helper"

RSpec.describe "Messages", type: :request do
  let(:user)         { create(:user) }
  let(:other_user)   { create(:user) }
  let(:conversation) { create(:conversation) }

  before do
    sign_in user
    create(:conversation_participant, conversation: conversation, user: user)
    create(:conversation_participant, conversation: conversation, user: other_user)
  end

  describe "GET /conversations/:id/messages" do
    it "lists messages" do
      create(:message, conversation: conversation, user: user, body: "one")
      create(:message, conversation: conversation, user: other_user, body: "two")

      get "/conversations/#{conversation.id}/messages", as: :json
      expect(response).to have_http_status(:ok)
      bodies = JSON.parse(response.body)["messages"].map { |m| m["body"] }
      expect(bodies).to include("one", "two")
    end
  end

  describe "POST /conversations/:id/messages" do
    it "creates a message" do
      post "/conversations/#{conversation.id}/messages", params: { body: "hi" }, as: :json
      expect(response).to have_http_status(:created)
    end

    it "rejects blank body" do
      post "/conversations/#{conversation.id}/messages", params: { body: "" }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

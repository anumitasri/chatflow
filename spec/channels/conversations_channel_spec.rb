require "rails_helper"

RSpec.describe ConversationsChannel, type: :channel do
  let(:user)         { create(:user) }
  let(:conversation) { create(:conversation) }

  before do
    create(:conversation_participant, conversation: conversation, user: user)
    stub_connection current_user: user
  end

  it "subscribes when user is a participant and streams for the conversation" do
    subscribe(conversation_id: conversation.id)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(conversation)
  end

  it "rejects when user is not a participant" do
    other_convo = create(:conversation)
    subscribe(conversation_id: other_convo.id)
    expect(subscription).to be_rejected
  end
end

require 'rails_helper'

RSpec.describe Message, type: :model do
  it "belongs to a conversation and user" do
    message = create(:message)
    expect(message.conversation).to be_a(Conversation)
    expect(message.user).to be_a(User)
  end
end

require 'rails_helper'

RSpec.describe Conversation, type: :model do
  it "can have participants" do
    conv = create(:conversation)
    user = create(:user)
    conv.participants << user
    expect(conv.participants).to include(user)
  end
end

require 'rails_helper'

RSpec.describe User, type: :model do
  it "is valid with valid attributes" do
    expect(build(:user)).to be_valid
  end

  it "is invalid without email" do
    expect(build(:user, email: nil)).not_to be_valid
  end
end

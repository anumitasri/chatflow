require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }
  before { sign_in user }

  it "GET /users/me returns current user" do
    get "/users/me", as: :json
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["id"]).to eq(user.id)
    expect(body["email"]).to eq(user.email)
  end
end

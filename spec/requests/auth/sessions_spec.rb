require 'rails_helper'

RSpec.describe "Auth::Sessions", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/auth/sessions/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/auth/sessions/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end

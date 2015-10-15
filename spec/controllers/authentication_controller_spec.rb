require 'rails_helper'

RSpec.describe AuthenticationController, type: :controller do

  describe "GET #registration" do
    it "returns http success" do
      get :registration
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #sign_in" do
    it "returns http success" do
      get :sign_in
      expect(response).to have_http_status(:success)
    end
  end

end

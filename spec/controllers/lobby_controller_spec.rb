require 'rails_helper'

RSpec.describe LobbyController, type: :controller do

  describe "GET #lobby" do
    it "returns http success" do
      get :lobby
      expect(response).to have_http_status(:success)
    end
  end

end

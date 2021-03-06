require 'spec_helper'

describe CoalescingPanda::Oauth2Controller, :type => :controller do
  routes { CoalescingPanda::Engine.routes }
  let(:account) { FactoryGirl.create(:account, settings: {base_url: 'foo.com'}) }
  let(:user) { FactoryGirl.create(:user, account: account) }

  describe "#redirect" do
    it 'creates a token in the db' do
      ENV['OAUTH_PROTOCOL'] = 'http'
      Bearcat::Client.any_instance.stub(retrieve_token: { 'access_token' => 'token', 'refresh_token' => 'token', 'expires_in' => 3600 })
      session[:state] = 'test'
      CoalescingPanda::OauthState.create!(state_key: session[:state], data: { key: account.key, user_id: user.id, api_domain: 'foo.com' })
      get :redirect, {user_id: user.id, api_domain: 'foo.com', code: 'bar', key: account.key, state: 'test'}
      auth = CoalescingPanda::CanvasApiAuth.find_by_user_id_and_api_domain(user.id, 'foo.com')
      auth.should_not == nil
      expect(auth.api_token).to eql 'token'
      expect(auth.refresh_token).to eql 'token'
      expect(auth.expires_at).to be > 50.minutes.from_now
    end

    it "doesn't create a token in the db" do
      get :redirect, {error: 'your face'}
      CoalescingPanda::CanvasApiAuth.all.count.should == 0
    end
  end

end

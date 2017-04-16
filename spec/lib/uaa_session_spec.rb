require 'spec_helper'

describe UaaSession do
  let(:access_token) { 'my_access_token' }
  let(:refresh_token) { 'my_refresh_token' }

  describe '.build' do
    let(:handler) { UaaSession.build(access_token, refresh_token) }
    let(:login_url) { 'http://login.example.com' }
    let(:uaa_url) { 'http://uaa.example.com' }
    let(:dashboard_client_id) { '<client id>' }
    let(:dashboard_client_secret) { '<client secret>' }

    before do
      allow(Configuration).to receive(:auth_server_url).and_return(login_url)
      allow(Configuration).to receive(:token_server_url).and_return(uaa_url)
      allow(Settings).to receive(:services).and_return(
        [
          double(dashboard_client: double(id: dashboard_client_id, secret: dashboard_client_secret))
        ]
      )
    end

    context 'when the access token is not expired' do
      before do
        allow(CF::UAA::TokenCoder).to receive(:decode).and_return('exp' => 1.minute.from_now.to_i)
      end

      it 'sets access token to the given token' do
        expect(handler.access_token).to eq(access_token)
      end

      it 'returns a token that is encoded and can be used in a header' do
        expect(handler.auth_header).to eql('bearer my_access_token')
      end
    end

    context 'when the access token is expired' do
      context 'and token_info symbolize_keys true' do
        let(:token_issuer) { double(CF::UAA::TokenIssuer, refresh_token_grant: token_info) }
        let(:token_info) { CF::UAA::TokenInfo.new(access_token: 'new_access_token', refresh_token: 'new_refresh_token', token_type: 'bearer') }

        before do
          allow(CF::UAA::TokenCoder).to receive(:decode).and_return('exp' => 1.minute.ago.to_i)

          expect(CF::UAA::TokenIssuer).to receive(:new).
            with(login_url, dashboard_client_id, dashboard_client_secret, { token_target: uaa_url }).
            and_return(token_issuer)
        end

        it 'uses the refresh token to get a new access token' do
          expect(handler.auth_header).to eql('bearer new_access_token')
        end

        it 'updates the tokens' do
          expect(handler.access_token).to eql('new_access_token')
        end
      end

      context 'and token_info default symbolize_keys' do
        let(:token_issuer) { double(CF::UAA::TokenIssuer, refresh_token_grant: token_info) }
        let(:token_info) { CF::UAA::TokenInfo.new("access_token" => 'new_access_token', "refresh_token" => 'new_refresh_token', "token_type" => 'bearer') }

        before do
          allow(CF::UAA::TokenCoder).to receive(:decode).and_return('exp' => 1.minute.ago.to_i)

          expect(CF::UAA::TokenIssuer).to receive(:new).
            with(login_url, dashboard_client_id, dashboard_client_secret, { token_target: uaa_url }).
            and_return(token_issuer)
        end

        it 'uses the refresh token to get a new access token' do
          expect(handler.auth_header).to eql('bearer new_access_token')
        end

        it 'updates the tokens' do
          expect(handler.access_token).to eql('new_access_token')
        end
      end
    end
  end

end

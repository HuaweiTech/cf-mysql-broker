# Inspired by rspec-rails' request example group.
module FeatureHelpers
  extend ActiveSupport::Concern
  include ActionDispatch::Integration::Runner

  included do
    metadata[:type] = :feature

    let(:default_env) do
      username = Settings.auth_username
      password = Settings.auth_password

      {
        'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
      }
    end
    let(:env) { default_env }

    before do
      @routes = ::Rails.application.routes
    end
  end

  def app
    ::Rails.application
  end

  def get(*args)
    args[2] ||= env
    super(*args)
  end

  def post(*args)
    args[2] ||= env
    super(*args)
  end

  def put(*args)
    args[2] ||= env
    super(*args)
  end

  def delete(*args)
    args[2] ||= env
    super(*args)
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, :example_group => { :file_path => %r(spec/features) }
end

class GoogleController < ApplicationController
  APPLICATION_NAME = ENV["PROJECT_ID"]
  TOKEN_PATH = Rails.root.join('config', 'token.yaml').to_s # TODO: needs to be per user
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

  def auth
    unless current_user
      redirect_to new_user_session_path, notice: "You must be logged in to access this page"
      return
    end

    code = params["code"]

    if code
      redirect_uri = ENV['REDIRECT_URI']
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: 'default', code: code, base_url: redirect_uri
      )
      flash[:notice] = "Successfully authenticated with Google"
      redirect_to email_index_path
    end
  end

  def authorizer
    client_id = Rails.application.credentials.dig(:gmail, :client_id)
    client_secret = Rails.application.credentials.dig(:gmail, :client_secret)
    client_id_obj = Google::Auth::ClientId.new(client_id, client_secret)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    Google::Auth::UserAuthorizer.new(client_id_obj, SCOPE, token_store)
  end
end

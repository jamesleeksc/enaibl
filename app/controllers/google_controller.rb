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
      begin
        credentials = authorizer.get_and_store_credentials_from_code(
          user_id: current_user.id, code: code, base_url: redirect_uri
        )
      rescue Signet::AuthorizationError => e
        Rails.logger.error("An error occurred: #{e.message}")

        credentials = authorize(current_user)

        if credentials.is_a?(String) && credentials.match?(/^http/)
          redirect_to credentials, allow_other_host: true
        else
          redirect_to root_path, alert: "An error occurred: #{e.message}"
        end

        return
      end

      flash[:notice] = "Successfully authenticated with Google"
      redirect_to email_index_path
    end
  end

  def authorizer
    client_id = Rails.application.credentials.dig(:gmail, :client_id)
    client_secret = Rails.application.credentials.dig(:gmail, :client_secret)
    redirect_uri = ENV['REDIRECT_URI']
    client_id_obj = Google::Auth::ClientId.new(client_id, client_secret)
    token_store = GoogleAuth::TokenStore.new(current_user)
    Google::Auth::UserAuthorizer.new(client_id_obj, SCOPE, token_store)
  end

  def google_callback
    user = current_user  # Assuming you have a method to get the logged-in user
    authorizer = authorize(user)

    if params[:code]
      # Exchange the authorization code for tokens
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user.id,
        code: params[:code],
        base_url: ENV['REDIRECT_URI']
      )

      # Now the tokens are stored in the database for the user
      redirect_to root_path, notice: 'Google account linked successfully'
    else
      redirect_to root_path, alert: 'Google authentication failed'
    end
  end

  def authorize(user)
    credentials = authorizer.get_credentials(user.id)
    if credentials.nil? || credentials.expired?
      url = authorizer.get_authorization_url(base_url: ENV['REDIRECT_URI'])
      return url
    end
    credentials
  end
end

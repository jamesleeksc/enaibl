class GoogleAuth::TokenStore
  def initialize(user)
    @user = user
  end

  def load(_user_id)
    # Load the tokens from the user
    return nil if @user.google_access_token.blank?

    Google::Auth::UserRefreshCredentials.new(
      client_id: Rails.application.credentials.dig(:gmail, :client_id),
      client_secret: Rails.application.credentials.dig(:gmail, :client_secret),
      scope: ['https://www.googleapis.com/auth/gmail.readonly'],
      access_token: @user.google_access_token,
      refresh_token: @user.google_refresh_token,
      expires_at: @user.google_expires_at,
      expiration_time_millis: @user.google_expires_at.to_i * 1_000,
      redirect_uri: ENV['REDIRECT_URI']
    ).to_json
  end

  def store(_user_id, credentials)
    # Save the credentials back to the user model
    credentials = JSON.parse(credentials)
    exp_s = credentials["expiration_time_millis"] / 1_000.0
    expires_at = Time.at(exp_s)

    @user.update(
      google_access_token: credentials["access_token"],
      google_refresh_token: credentials["refresh_token"],
      google_expires_at: expires_at
    )
  end
end

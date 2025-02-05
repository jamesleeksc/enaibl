require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'

class EmailController < ApplicationController
  APPLICATION_NAME = ENV["PROJECT_ID"]
  TOKEN_PATH = Rails.root.join('config', 'token.yaml').to_s # TODO: needs to be per user
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

  def index
    # TODO: pagination and search
    @emails = Email.where(user_id: current_user).or(Email.where(client_account: current_user.client_account)).all
    shipment_ids = @emails.joins(:shipments).pluck('shipments.id').uniq
    @shipments = Shipment.where(id: shipment_ids)
  end

  def edit
    # edit email and related settings
  end

  def sync
    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = APPLICATION_NAME
    authorization = authorize

    if authorization.is_a?(String) && authorization.match?(/^http/)
      redirect_to authorization, allow_other_host: true
    else
      @service.authorization = authorization
      gmail_service = GmailService.new(authorization)
      # thread_snippets = gmail_service.list_messages

      # @threads = thread_snippets.map do |snippet|
      #   gmail_service.get_thread(snippet.id)
      # end

      @message_pointers = gmail_service.list_messages
      @messages = @message_pointers.map do |message|
        gmail_service.get_message(message.id)
      end

      @messages.each do |message|
        parsed = gmail_service.parse_message(message)
        next if Email.find_by(platform_id: message.id)
        Email.create(
          to: parsed[:to],
          from: parsed[:from],
          subject: parsed[:subject],
          body: parsed[:body],
          date: parsed[:date],
          platform: 'gmail',
          platform_id: message.id,
          user: current_user,
          client_account: current_user.client_account
        )
      end

      respond_to do |format|
        format.js   # sync.js.erb
        format.html { redirect_to email_index_path }  # Fallback for non-JS
      end
    end
  end

  def authorize
    client_id = Rails.application.credentials.dig(:gmail, :client_id)
    client_secret = Rails.application.credentials.dig(:gmail, :client_secret)
    redirect_uri = ENV['REDIRECT_URI']

    client_id_obj = Google::Auth::ClientId.new(client_id, client_secret)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id_obj, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)

    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: redirect_uri)
      return url
    end

    credentials
  end

  def list_messages
    user_id = 'me'
    result = @service.list_user_messages(user_id)
    result.messages || []
  end
end

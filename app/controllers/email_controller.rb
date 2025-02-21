require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'

class EmailController < ApplicationController
  APPLICATION_NAME = ENV["PROJECT_ID"]
  TOKEN_PATH = Rails.root.join('config', 'token.yaml').to_s # TODO: needs to be per user
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

  def index
    # TODO: pagination and search
    if params[:include_account_emails]
      @emails = Email.where(user_id: current_user).or(Email.where(client_account: current_user.client_account)).all
    else
      @emails = Email.where(user_id: current_user).all
    end

    @emails = @emails.order(date: :desc).page(params[:page])
    shipment_ids = @emails.joins(:shipments).pluck('shipments.id').uniq
    @shipments = Shipment.where(id: shipment_ids)
  end

  def edit
    # edit email and related settings
  end

  def sync
    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = APPLICATION_NAME
    authorization = authorize(current_user)

    if authorization.is_a?(String) && authorization.match?(/^http/)
      redirect_to authorization, allow_other_host: true
    else
      @service.authorization = authorization
      start_date = current_user.emails.order(:date).last&.date
      # NOTE: in some cases, the following appears to skip some dates
      # Emails are not processed chronologically so if this gets interrupted (possibly by token expiration) we may have saved an email with a later date than the some of the emails queued for processing
      gmail_service = GmailService.new(user: current_user, authorization: authorization, start_date: start_date)

      @message_pointers = gmail_service.list_messages

      @message_pointers.each_slice(50) do |batch|
        message_ids = batch.map(&:id)
        messages = gmail_service.get_messages_batch(message_ids)

        messages.each do |message|
          next if Email.find_by(platform_id: message.id)
          parsed = gmail_service.parse_message(message)

          begin
            email = Email.create(
              to: sanitize_text(parsed[:to]),
              from: sanitize_text(parsed[:from]),
              subject: sanitize_text(parsed[:subject]),
              body: sanitize_text(parsed[:body]),
              date: parsed[:date],
              platform: 'gmail',
              platform_id: message.id,
              user: current_user,
              client_account: current_user.client_account
            )

            if parsed[:attachments].present?
              parsed[:attachments].each do |attachment|
                filename = sanitize_filename(attachment[:filename])
                doc = email.documents.create(
                  filename: filename,
                  user: current_user,
                  client_account: current_user.client_account
                )

                attachment_data = attachment[:data]
                attachment_data.rewind

                doc.file.attach(io: attachment[:data], filename: filename, content_type: attachment[:mime_type])
              end
            end
          rescue ActiveRecord::StatementInvalid => e
            Rails.logger.error("Failed to create email for message #{message.id}: #{e.message}")
            next
          end
        end
      end

      respond_to do |format|
        format.js   # sync.js.erb
        format.html { redirect_to email_index_path }  # Fallback for non-JS
      end
    end
  end

  # def authorize
  #   client_id = Rails.application.credentials.dig(:gmail, :client_id)
  #   client_secret = Rails.application.credentials.dig(:gmail, :client_secret)
  #   redirect_uri = ENV['REDIRECT_URI']

  #   client_id_obj = Google::Auth::ClientId.new(client_id, client_secret)
  #   token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
  #   authorizer = Google::Auth::UserAuthorizer.new(client_id_obj, SCOPE, token_store)
  #   user_id = 'default'
  #   credentials = authorizer.get_credentials(user_id)

  #   if credentials.nil? || credentials.expired?
  #     url = authorizer.get_authorization_url(base_url: redirect_uri)
  #     return url
  #   end

  #   credentials
  # end


  def authorize(user)
    client_id = Rails.application.credentials.dig(:gmail, :client_id)
    client_secret = Rails.application.credentials.dig(:gmail, :client_secret)
    redirect_uri = ENV['REDIRECT_URI']
    client_id_obj = Google::Auth::ClientId.new(client_id, client_secret)
    token_store = GoogleAuth::TokenStore.new(user)
    authorizer = Google::Auth::UserAuthorizer.new(client_id_obj, SCOPE, token_store)
    credentials = authorizer.get_credentials(user.id)
    if credentials
      credentials.expires_at = user&.google_expires_at
    end

    if credentials.nil? || credentials.expired?
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

  def sanitize_filename(filename)
    filename.gsub(/[^0-9A-Za-z.\-]/, '_')
  end

  private

  def sanitize_text(text)
    return "" if text.nil?
    text.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  end
end

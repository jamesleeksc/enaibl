# app/services/gmail_service.rb
require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'

class GmailService
  APPLICATION_NAME = ENV["PROJECT_ID"]
  TOKEN_PATH = Rails.root.join('config', 'token.yaml').to_s # TODO: needs to be per user
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY
  MAX_RESULTS = 500 # Maximum allowed by Gmail API

  def initialize(user:, authorization: nil, max_results: 1000, start_date: nil)
    return unless user
    @start_date = start_date
    @max_results = max_results
    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorization
  end

  def list_messages(page_token = nil)
    user_id = 'me'
    start_query = "after:#{@start_date.strftime('%Y/%m/%d')}" if @start_date
    messages = []
    result = @service.list_user_messages(user_id, max_results: @max_results, q: start_query, page_token: page_token)
    messages += result.messages || []

    if result.next_page_token && messages.size < @max_results
      messages += list_messages(result.next_page_token)
    end

    messages
  end

  def get_message(message_id)
    user_id = 'me'
    @service.get_user_message(user_id, message_id)
  end

  def fetch_email_raw(msg_id)
    begin
      msg = @service.get_user_message('me', msg_id, format: 'raw')
      msg_str = sanitize_base64(msg.raw)
      mime_msg = Mail.read_from_string(Base64.decode64(msg_str))
      mime_msg
    rescue Google::Apis::Error => e
      Rails.logger.error("An error occurred: #{e.message}")
      nil
    end
  end

  def list_threads
    user_id = 'me'
    result = @service.list_user_threads(user_id, max_results: @max_results)
    result.threads || []
  end

  def get_thread(thread_id)
    user_id = 'me'
    @service.get_user_thread(user_id, thread_id)
  end

  def get_gmail_messages(start_date: nil, page_token: nil)
    query = start_date ? "after:#{start_date.strftime('%Y/%m/%d')}" : ''

    results = @service.list_user_messages('me', q: query, max_results: MAX_RESULTS, page_token: page_token)
    messages = results.messages || []
    next_page_token = results.next_page_token

    [messages, next_page_token]
  rescue Google::Apis::Error => e
    Rails.logger.error("An error occurred: #{e.message}")
    [[], nil]
  end

  # Fetch individual email by ID
  def fetch_email(msg_id)
    begin
      msg = @service.get_user_message('me', msg_id, format: 'full')
      msg
    rescue Google::Apis::Error => e
      Rails.logger.error("An error occurred: #{e.message}")
      nil
    end
  end

  def extract_body_and_attachments(payload, msg_id)
    body = ""
    attachments = []

    if payload.parts
      payload.parts.each do |part|
        if part.mime_type == 'text/plain' || part.mime_type == 'text/html'
          body += extract_text(part.body, msg_id)
        elsif part.mime_type.start_with?('multipart/')
          nested_body, nested_attachments = extract_body_and_attachments(part, msg_id)
          body += nested_body if nested_body.present?
          attachments.concat(nested_attachments) if nested_attachments.any?
        elsif part.filename.present? || part.mime_type == 'application/octet-stream'
          attachment_data = part.body.data || fetch_attachment_data(part, msg_id)
          attachments << {
            filename: part.filename || "attachment_#{msg_id}",
            mime_type: part.mime_type,
            data: StringIO.new(attachment_data)
          }
        end
      end
    end

    # If no body was found in parts, check the main payload body
    if body.empty? && payload.body
      body = extract_text(payload.body, msg_id)
    end

    [body, attachments]
  end

  def fetch_attachment_data(part, msg_id)
    attachment_id = if part.is_a?(Google::Apis::GmailV1::MessagePart)
                      part.body&.attachment_id
                    else
                      part.attachment_id
                    end

    return unless attachment_id

    begin
      attachment = @service.get_user_message_attachment('me', msg_id, attachment_id)
      attachment.data
    rescue Google::Apis::Error => e
      Rails.logger.error("Failed to fetch attachment for message #{msg_id}: #{e.message}")
      nil
    end
  end

  # Decode base64 content safely
  def decode_base64(data)
    sanitized_data = sanitize_base64(data)
    Base64.urlsafe_decode64(sanitized_data)
  rescue ArgumentError => e
    Rails.logger.error("Failed to decode email body: #{e.message}")
    ""
  end

  def parse_message(message)
    body, attachments = extract_body_and_attachments(message.payload, message.id)
    headers = message.payload.headers
    {
      from: sanitize_text(headers.find { |h| h.name == 'From' }&.value),
      to: sanitize_text(headers.find { |h| h.name == 'To' }&.value),
      subject: sanitize_text(headers.find { |h| h.name == 'Subject' }&.value),
      date: headers.find { |h| h.name == 'Date' }&.value,
      body: body,
      attachments: attachments
    }
  end

  def get_messages_batch(message_ids)
    messages = []

    @service.batch do |service|
      message_ids.each do |id|
        service.get_user_message('me', id, format: 'full') do |message, err|
          if err
            Rails.logger.error "Error fetching message #{id}: #{err}"
          else
            messages << message
          end
        end
      end
    end

    messages
  end

  private

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
      return false
      # NOTE: Handled in email_controller
    end

    credentials
  end

  def decode_base64(data)
    Base64.urlsafe_decode64(data)
  rescue ArgumentError => e
    Rails.logger.error("Failed to decode email body: #{e.message}")
    ""
  end

  def sanitize_base64(data)
    data.tr("\n", '').tr('_-', '+/')
  end

  def extract_text(body_part, msg_id)
    if body_part.data
      body_part.data
    elsif body_part.attachment_id
      fetch_attachment_data(body_part, msg_id)
    else
      ""
    end
  end

  def sanitize_text(text)
    return "" if text.nil?
    text.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  end
end

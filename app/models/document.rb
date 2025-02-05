class Document < ApplicationRecord
  belongs_to :client_account, optional: true
  belongs_to :user, optional: true

  after_save :extract_text

  has_one_attached :file

  private
  def extract_text
    # TODO: move to background job or lambda function
  end
end

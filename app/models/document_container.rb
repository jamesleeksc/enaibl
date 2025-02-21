# Join/reference for documents and containers
class DocumentContainer < ApplicationRecord
  belongs_to :document
  belongs_to :container
end

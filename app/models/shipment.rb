class Shipment < ApplicationRecord
  has_and_belongs_to_many :emails
  belongs_to :client_account
end

class Organization < ApplicationRecord
  belongs_to :client_account
  has_many :organization_contacts
end

class Location < ApplicationRecord
  belongs_to :client_account, optional: true
end

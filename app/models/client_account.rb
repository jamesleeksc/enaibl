class ClientAccount < ApplicationRecord
  has_many :organizations
  has_many :users
end

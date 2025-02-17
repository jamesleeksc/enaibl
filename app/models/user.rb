class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :client_account
  has_many :emails
  has_many :documents
  has_many :organizations

  def all_documents
    Document.where(user_id: id).or(Document.where(client_account_id: client_account_id))
  end
end

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :properties, dependent: :destroy
  has_many :transactions, dependent: :nullify
  has_many :chains, dependent: :nullify
  has_many :involved_parties, dependent: :nullify

  validates :user_name, presence: true
  validates :password, format: { with: /\A(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}\z/, message: "must be at least 8 characters and include at least one letter and one number" }, if: :password_required?
end

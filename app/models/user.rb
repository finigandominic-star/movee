class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :properties

  validates :user_name, presence: true
  validates :email, presence: true
  validates :password, presence: true, format: { with: "^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$" }
end

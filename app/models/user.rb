class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :properties, dependent: :destroy
  has_many :transactions, dependent: :nullify
  has_many :chains, dependent: :nullify
  has_many :involved_parties, dependent: :nullify
  has_many :transaction_share_links, dependent: :nullify
  has_many :chats, dependent: :destroy

  has_one_attached :avatar

  has_many :client_documents, dependent: :destroy

  validates :user_name, presence: true
  validates :password, format: { with: /\A(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}\z/, message: "must be at least 8 characters and include at least one letter and one number" }, if: :password_required?

  # for the background job app/jobs/update_user_job.rb to work we need this method and the private async_update
  # ToDo: check if it makes more sense to enqueue from the controller (see lecture from Oct. 15)
  # and then decide from where to enqueue

  after_commit :async_update, on: %i[create update]

  private

  def async_update
    UpdateUserJob.perform_later(self)
  end
end

class Message < ApplicationRecord
  belongs_to :chat

  validates :content, presence: true

  # if we have time to refactor we could use act_as (need code changes in other files as well)
  # acts_as_message
end

class Chat < ApplicationRecord
  belongs_to :user

  has_many :messages, dependent: :destroy

  # if we have time to refactor we could use act_as (need code changes in other files as well)
  # acts_as_chat

  DEFAULT_TITLE = "Untitled"
  TITLE_PROMPT = <<~PROMPT
    Generate a short, descriptive, 3-to-6-word title that summarizes the user question for a chat conversation.
  PROMPT

  def generate_title_from_first_message
    return unless title == DEFAULT_TITLE

    first_user_message = messages.where(role: "user").order(:created_at).first
    return if first_user_message.nil?

    response = RubyLLM.chat.with_instructions(TITLE_PROMPT).ask(first_user_message.content)
    update(title: response.content)
  end

end

class CreateChatAssistantMessageJob < ApplicationJob
  queue_as :default

  def perform(user_message)
    # we might want to still configure when the job is performed
    @message = user_message
    @chat = user_message.chat

    # ToDo: modify this line to work with our app instead of challenges model: probably to the realtor user itself
    # @challenge = @chat.challenge -> probably: @user = current_user

    # Initialize as instance variable so other methods can see it -- if not needed, just ruby_llm_chat = ...
    @ruby_llm_chat = RubyLLM.chat

    build_conversation_history
    # Ensure instructions returns a string
    response = @ruby_llm_chat.with_instructions(instructions).ask(@message.content)

    @assistant_message = Message.create(role: "assistant", content: response.content, chat: @chat)

    response = ask_llm
    @assistant_message.update(content: response.content)

    broadcast_replace(@assistant_message)

    @chat.generate_title_from_first_message

      # use these lines without Turbo Stream
      # redirect_to chat_path(@chat)
      # else
        # render "chats/show", status: :unprocessable_entity
      # end
  end

  def build_conversation_history
    # Assuming @ruby_llm_chat is already initialized in 'create'
    @chat.messages.each do |message|
      # might need to be modifiyed, to ensure we pass the correct arguments to add_message based on our use cases for RubyLLM class
      @ruby_llm_chat.add_message(message)
    end
  end

  # all other methods need to go here as wwll (not into messages_controller)

  private

  # placeholder context method to give context to the LLM
  # ToDO: modify it to our app
  # def challenge_context
  #   "Here is the context of the challenge: #{@challenge.content}."
  # end

  def instructions
    # properly define context and instance for the .system_propmt
    # [SYSTEM_PROMPT, challenge_context, @challenge.system_prompt].compact.join("\n\n")
  end

end

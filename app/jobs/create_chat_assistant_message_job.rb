class CreateChatAssistantMessageJob < ApplicationJob
  include ActionView::RecordIdentifier

  # ToDo: add our system prompt
  SYSTEM_PROMPT = <<~PROMPT

  PROMPT

  # TODO: if we need a constant, it goes here

  queue_as :default

  def perform(user_message)
    # we might want to still configure when the job is performed
    @message = user_message
    @chat = user_message.chat

    # ToDo: modify this line to work with our app instead of challenges model: probably to the realtor user itself
    # @challenge = @chat.challenge -> probably: @user = current_user

    @assistant_message = @chat.messages.create(role: "assistant", content: "")

    response = ask_llm
    @assistant_message.update(content: response.content)
    broadcast_replace(@assistant_message)

    @chat.generate_title_from_first_message

    if @chat.title_previously_changed?
      Turbo::StreamsChannel.broadcast_update_to(@chat, target: "chat_title", content: @chat.title)
    end
  end

  def build_conversation_history
    # Assuming @ruby_llm_chat is already initialized in 'create'
    @chat.messages.each do |message|
      # might need to be modifiyed, to ensure we pass the correct arguments to add_message based on our use cases for RubyLLM class
      @ruby_llm_chat.add_message(message)
    end
  end

  private
  # all other methods for our use case(s) need to go here as wwll (not into messages_controller)
  def ask_llm
    @ruby_llm_chat = RubyLLM.chat

    build_conversation_history

    # placehoders for our tools we want to give the LLM based on our use case(s)
    # @ruby_llm_chat.with_tool(SearchChallengesTool)
    # @ruby_llm_chat.with_tool(AvailableTeachersTool.new(batch_number: BATCH_NUMBER))
    # @ruby_llm_chat.with_tool(CreateHelpTicketTool.new(user: @chat.user))
    @ruby_llm_chat.with_instructions(instructions)

    @ruby_llm_chat.ask(@message.content) do |chunk|
      next if chunk.content.blank? # skip empty chunks

      @assistant_message.content += chunk.content
      broadcast_replace(@assistant_message)
    end
  end

  def broadcast_replace(message)
    Turbo::StreamsChannel.broadcast_replace_to(@chat, target: dom_id(message), partial: "messages/message", locals: { message: message })
  end

  def build_conversation_history
    @chat.messages.each do |message|
      next if message.content.blank?

      @ruby_llm_chat.add_message(message)
    end
  end

  # placeholder context method to give context to the LLM
  # ToDO: modify it to our app
  # def challenge_context
  #   "Here is the context of the challenge: #{@challenge.content}."
  # end

  def instructions
    # placeholder for now
    # ToDo: properly define context and instance for the .system_propmt
    # [SYSTEM_PROMPT, challenge_context, @challenge.system_prompt].compact.join("\n\n")  end
end

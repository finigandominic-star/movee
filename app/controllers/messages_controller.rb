class MessagesController < ApplicationController
  # ToDo: modify the system prompt,
  #   the context method,
  #   the instruction method,
  #   add other methods as needed

  SYSTEM_PROMPT = "You are a Teaching Assistant.\n\n" \
                  "I am a student at the Le Wagon Web Development Bootcamp, learning how to code.\n\n" \
                  "Help me break down my problem into small, actionable steps, without giving away solutions.\n\n" \
                  "Answer concisely in Markdown."

  def create
    @chat = current_user.chats.find(params[:chat_id])
    # make it fit to our app: @challenge = @chat.challenge
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      # Initialize as instance variable so other methods can see it -- if not needed, just ruby_llm_chat = ...
      @ruby_llm_chat = RubyLLM.chat

      build_conversation_history
      # Ensure instructions returns a string
      response = @ruby_llm_chat.with_instructions(instructions).ask(@message.content)

      Message.create(role: "assistant", content: response.content, chat: @chat)
      @chat.generate_title_from_first_message

      # use these lines without Turbo Stream
      # redirect_to chat_path(@chat)
      # else
        # render "chats/show", status: :unprocessable_entity
      # end

      # use this version with Turbo Stream
      respond_to do |format|
        format.turbo_stream # renders `app/views/messages/create.turbo_stream.erb`
        format.html { redirect_to chat_path(@chat) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("new_message_container", partial: "messages/form", locals: { chat: @chat, message: @message }) }
        format.html { render "chats/show", status: :unprocessable_entity }
      end
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

  # placeholder context method to give context to the LLM
  # modify it to our app
  # def challenge_context
  #   "Here is the context of the challenge: #{@challenge.content}."
  # end

  def instructions
    # properly define context and instance for the .system_propmt
    # [SYSTEM_PROMPT, challenge_context, @challenge.system_prompt].compact.join("\n\n")
  end

  def message_params
    params.require(:message).permit(:content)
  end
end

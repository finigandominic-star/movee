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
    # for background jobs: moved most methods to create_chat_assistant_message_job


    # with background jobs: this needs to stay here
    # ToDo: check for our use case if the path can be used or if we need another path
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

   # all other methods need to go create_chat_assistant_message_job as wwll (not here)

  private

  # for background jobs: moved most methods to create_chat_assistant_message_job

  def message_params
    params.require(:message).permit(:content)
  end
end

class ChatsController < ApplicationController
  def create
    # we need something like this @challenge = Challenge.find(params[:challenge_id])

    @chat = Chat.new(title: Chat::DEFAULT_TITLE)
    # also something like this: @chat.challenge = @challenge
    @chat.user = current_user

    if @chat.save
      redirect_to chat_path(@chat)
    else
      # properly define where else we want to sent the reponse @chats = @challenge.chats.where(user: current_user)
      # correct path for: render "challenges/show"
    end
  end

  def show
    @chat    = current_user.chats.find(params[:id])
    @message = Message.new
  end
end

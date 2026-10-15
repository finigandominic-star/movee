class MessagesController < ApplicationController
  # modify the system promot
  SYSTEM_PROMPT = "You are a Teaching Assistant.\n\nI am a student at the Le Wagon Web Development Bootcamp, learning how to code.\n\nHelp me break down my problem into small, actionable steps, without giving away solutions.\n\nAnswer concisely in Markdown."

  def create
  end

  private

  def instructions
    # properly define context and instance for the .system_propmt
    # [SYSTEM_PROMPT, challenge_context, @challenge.system_prompt].compact.join("\n\n")
  end

  def message_params
    params.require(:message).permit(:content)
  end

end

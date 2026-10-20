# Finds the client's details in an uploaded document's text, in the background (the AI takes a few seconds).

class ExtractClientDetailsJob < ApplicationJob
  queue_as :default

  # The document was deleted before the job ran: nothing left to do
  discard_on ActiveJob::DeserializationError

  # llm: is only passed in tests (a fake); the app uses the default RubyLLM.chat
  def perform(client_document, llm: RubyLLM.chat)
    # if the job somehow runs twice, the second run does nothing and doesn't overwrite a finished result.
    return unless client_document.processing?

    details = ClientDetailsExtractor.call(client_document.content, llm: llm)
    client_document.update!(extracted_data: details, status: "done")

  # Any AI problem ends up as status failed, with the message saved for the realtor to see.
  rescue ClientDetailsAi::Error => e
    client_document.update!(status: "failed", error_message: e.message)
  end
end

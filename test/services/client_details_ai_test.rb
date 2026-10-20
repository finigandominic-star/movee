require "test_helper"

class ClientDetailsAiTest < ActiveSupport::TestCase
  # Stands in for RubyLLM.chat, so the tests never call OpenAI
  class FakeChat
    attr_reader :instructions, :schema, :question

    def initialize(answer)
      @answer = answer
    end

    def with_instructions(instructions)
      @instructions = instructions
      self
    end

    def with_schema(schema)
      @schema = schema
      self
    end

    def ask(question)
      @question = question
      Struct.new(:parsed).new(@answer)
    end
  end

  test "returns the details from the assistant's answer" do
    chat = FakeChat.new({ "first_name" => "Tunde", "last_name" => "Adebayo", "onward_purchase" => "buying" })

    details = ClientDetailsAi.call("some PDF text", chat: chat)

    assert_equal "Tunde", details["first_name"]
    assert_equal "Adebayo", details["last_name"]
    assert_equal "buying", details["onward_purchase"]
  end

  test "sends the PDF text with the instructions and the schema" do
    chat = FakeChat.new({})

    ClientDetailsAi.call("some PDF text", chat: chat)

    assert_equal "some PDF text", chat.question
    assert_equal ClientDetailsAi::INSTRUCTIONS, chat.instructions
    assert_equal ClientDetailsAi::SCHEMA, chat.schema
  end

  test "keeps only the fields we asked for" do
    chat = FakeChat.new({ "first_name" => "Tunde", "favourite_colour" => "blue" })

    details = ClientDetailsAi.call("some PDF text", chat: chat)

    assert_equal({ "first_name" => "Tunde" }, details)
  end

  test "raises a clear error when the assistant gives no answer" do
    error = assert_raises(ClientDetailsAi::Error) do
      ClientDetailsAi.call("some PDF text", chat: FakeChat.new(nil))
    end

    assert_equal "The assistant gave no answer.", error.message
  end
end

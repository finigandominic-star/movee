require "test_helper"

class ClientDetailsAiTest < ActiveSupport::TestCase
  test "returns the details from the assistant's answer" do
    llm = FakeChat.new({ "first_name" => "Tunde", "last_name" => "Adebayo", "onward_purchase" => "buying" })

    details = ClientDetailsAi.call("some PDF text", llm: llm)

    assert_equal "Tunde", details["first_name"]
    assert_equal "Adebayo", details["last_name"]
    assert_equal "buying", details["onward_purchase"]
  end

  test "sends the PDF text with the instructions and the schema" do
    llm = FakeChat.new({})

    ClientDetailsAi.call("some PDF text", llm: llm)

    assert_equal "some PDF text", llm.question
    assert_equal ClientDetailsAi::INSTRUCTIONS, llm.instructions
    assert_equal ClientDetailsAi::SCHEMA, llm.schema
  end

  test "keeps only the fields we asked for" do
    llm = FakeChat.new({ "first_name" => "Tunde", "favourite_colour" => "blue" })

    details = ClientDetailsAi.call("some PDF text", llm: llm)

    assert_equal({ "first_name" => "Tunde" }, details)
  end

  test "raises a clear error when the assistant gives no answer" do
    error = assert_raises(ClientDetailsAi::Error) do
      ClientDetailsAi.call("some PDF text", llm: FakeChat.new(nil))
    end

    assert_equal "The assistant gave no answer.", error.message
  end
end

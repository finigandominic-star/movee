# Stands in for RubyLLM.chat in tests, so they never call OpenAI.
# It answers every question with the answer it was given, and remembers what it received.
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

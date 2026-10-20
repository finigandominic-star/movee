# for now an empty file
# use if we're going to have the LLM Agent use an API

require 'open-uri'

class ApiTool < RubyLLM::Tool
  description "What this tool does"
  parameter :name, description: "What this param is"

  def initialize (some_thing:)
    # @some_thing = some_thing
  end

  def execute(name:)
    # url = "https://.../#{some_thing}/..."
    # JSON.parse(URI.parse(url).read)
    # rescue => e # If the API fails, return an error the LLM can explain
    # { error: e.message }
  end
end

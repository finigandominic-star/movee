# for now just a bare bones skelleton
# use and define properly when we want to give the LLM Agent some tool to work with
class ExampleTool < RubyLLM::Tool
  description "What this tool does"
  param :name, desc: "What this param is"

  def execute(name:)
    # the actual work
  end
end

# using this fake job for now to test the background jobs and
# to have something for when we have use cases for the Assistant
# ToDo: when we do have them, probably delete this file and make a new fake job with "rails generate job <name>"
class FakeJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "I'm starting the fake job"
    sleep 3
    puts "OK I'm done now"
  end
end

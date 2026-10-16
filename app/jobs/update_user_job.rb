# using this fake job for now to test the background jobs and
# to have something for when we have use cases for the Assistant
# ToDo: when we do have them, decide whether this job makes sense for our app
class UpdateUserJob < ApplicationJob
  queue_as :default

  def perform(user)
    puts "Calling Clearbit API for #{user.email}..."
    # TODO: perform a time consuming task like Clearbit's Enrichment API.
    sleep 2
    puts "Done! Enriched #{user.email} with Clearbit"
  end
end

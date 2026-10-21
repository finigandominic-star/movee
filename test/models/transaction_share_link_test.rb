require "test_helper"

class TransactionShareLinkTest < ActiveSupport::TestCase
  setup do
    agent = User.create!(email: "agent@example.com", user_name: "Agent", password: "Password123")
    property = Property.create!(house_number: "12", street: "Elm Rd", city: "Bristol", post_code: "BS1 1AA",
                                user: agent)
    @transaction = Transaction.create!(property: property, user: agent)
    @agent = agent
  end

  test "create_for! sets expires_at from the chosen duration and generates a unique token" do
    link = TransactionShareLink.create_for!(@transaction, user: @agent, duration: "5h")

    assert link.token.present?
    assert_equal @transaction, link.deal
    assert_in_delta 5.hours.from_now, link.expires_at, 5.seconds
    assert_not link.expired?
  end

  test "expired? is true once expires_at has passed" do
    link = TransactionShareLink.create_for!(@transaction, user: @agent, duration: "30m")
    link.update!(expires_at: 1.second.ago)

    assert link.expired?
  end

  test "an unknown duration key raises" do
    assert_raises(KeyError) do
      TransactionShareLink.create_for!(@transaction, user: @agent, duration: "forever")
    end
  end

  # Regression: db/seeds.rb calls User.destroy_all as its first cleanup step,
  # before transactions/chains/etc are touched. This previously raised
  # ActiveRecord::InvalidForeignKey whenever the generating user wasn't the
  # transaction/property's own owner (e.g. an admin sharing someone else's
  # transaction) - the Property-destroy cascade doesn't reach that link at all,
  # so only the generating user's own association/FK rule can save it.
  test "destroying the user who generated a link (but doesn't own the transaction) nullifies it instead of blocking" do
    admin = User.create!(email: "admin@example.com", user_name: "Admin", password: "Password123", admin: true)
    link = TransactionShareLink.create_for!(@transaction, user: admin, duration: "1h")

    assert_nothing_raised { admin.destroy }

    assert_nil link.reload.user_id
    assert @transaction.reload.present?
  end
end

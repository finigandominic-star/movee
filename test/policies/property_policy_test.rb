require "test_helper"

class PropertyPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = User.create!(user_name: "owner", email: "owner_pol@example.com", password: "Password123", admin: false)
    @other_user = User.create!(user_name: "other", email: "other_pol@example.com", password: "Password123", admin: false)
    @admin = User.create!(user_name: "admin", email: "admin_pol@example.com", password: "Password123", admin: true)
    @property = Property.create!(user: @owner, house_number: "1", street: "Test St", post_code: "SW1A 1AA")
  end

  def test_scope
    assert_includes PropertyPolicy::Scope.new(@owner, Property.all).resolve, @property
    assert_includes PropertyPolicy::Scope.new(@admin, Property.all).resolve, @property
  end

  def test_show
    assert PropertyPolicy.new(@owner, @property).show?
    assert PropertyPolicy.new(@other_user, @property).show?
    assert PropertyPolicy.new(@admin, @property).show?
  end

  def test_create
    assert PropertyPolicy.new(@owner, Property.new).create?
    assert PropertyPolicy.new(@admin, Property.new).create?
  end

  def test_update
    assert PropertyPolicy.new(@owner, @property).update?
    assert_not PropertyPolicy.new(@other_user, @property).update?
    assert PropertyPolicy.new(@admin, @property).update?
  end

  def test_destroy
    assert PropertyPolicy.new(@owner, @property).destroy?
    assert_not PropertyPolicy.new(@other_user, @property).destroy?
    assert PropertyPolicy.new(@admin, @property).destroy?
  end
end

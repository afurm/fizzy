require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "belongs to identity" do
    session = sessions(:david)
    assert_equal identities(:david), session.identity
  end

  test "creates session for identity" do
    identity = identities(:david)
    session = Session.create!(identity: identity)

    assert_equal identity, session.identity
    assert session.persisted?
  end

  test "multiple sessions can belong to same identity" do
    identity = identities(:david)

    session1 = Session.create!(identity: identity)
    session2 = Session.create!(identity: identity)

    assert_equal identity, session1.identity
    assert_equal identity, session2.identity
    assert_not_equal session1, session2
  end
end

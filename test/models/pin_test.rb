require "test_helper"

class PinTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "belongs to account, card, and user" do
    pin = pins(:logo_kevin)
    assert_equal accounts("37s"), pin.account
    assert_equal cards(:logo), pin.card
    assert_equal users(:kevin), pin.user
  end

  test "creates pin with default account from user" do
    pin = Pin.create!(card: cards(:logo), user: users(:david))
    assert_equal users(:david).account, pin.account
  end

  test "ordered scope returns pins in descending created_at order" do
    user = users(:david)
    card1 = cards(:logo)
    card2 = cards(:layout)

    pin1 = Pin.create!(card: card1, user: user)

    travel 1.minute do
      pin2 = Pin.create!(card: card2, user: user)

      pins = Pin.where(user: user).ordered
      assert_equal pin2, pins.first
      assert_equal pin1, pins.last
    end
  end

  test "user can pin multiple cards" do
    user = users(:kevin)
    assert_equal 2, user.pins.count
    assert_includes user.pins.map(&:card), cards(:logo)
    assert_includes user.pins.map(&:card), cards(:shipping)
  end

  test "card can be pinned by multiple users" do
    card = cards(:logo)
    users(:david).pins.create!(card: card)

    assert_operator card.pins.count, :>=, 2
  end
end

require "test_helper"

class ClosureTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "belongs to account, card, and user" do
    closure = closures(:shipping)
    assert_equal accounts("37s"), closure.account
    assert_equal cards(:shipping), closure.card
    assert_equal users(:kevin), closure.user
  end

  test "creates closure with default account from card" do
    card = cards(:logo)
    closure = Closure.create!(card: card, user: users(:david))
    assert_equal card.account, closure.account
  end

  test "user is optional" do
    card = cards(:logo)
    closure = Closure.new(card: card)
    assert closure.valid?
  end

  test "touches card when created" do
    card = cards(:logo)
    original_updated_at = card.updated_at

    travel 1.minute do
      Closure.create!(card: card, user: users(:david))
      assert card.reload.updated_at > original_updated_at
    end
  end

  test "touches card when updated" do
    closure = closures(:shipping)
    card = closure.card
    original_updated_at = card.updated_at

    travel 1.minute do
      closure.update!(user: users(:david))
      assert card.reload.updated_at > original_updated_at
    end
  end

  test "touches card when destroyed" do
    closure = closures(:shipping)
    card = closure.card
    original_updated_at = card.updated_at

    travel 1.minute do
      closure.destroy
      assert card.reload.updated_at > original_updated_at
    end
  end
end

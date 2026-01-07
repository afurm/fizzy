require "test_helper"

class WatchTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "belongs to account, user, and card" do
    watch = watches(:logo_david)
    assert_equal accounts("37s"), watch.account
    assert_equal users(:david), watch.user
    assert_equal cards(:logo), watch.card
  end

  test "creates watch with default account from user" do
    watch = Watch.create!(card: cards(:layout), user: users(:jz), watching: true)
    assert_equal users(:jz).account, watch.account
  end

  test "watching scope returns only watching records" do
    watching_watches = Watch.watching
    watching_watches.each do |watch|
      assert watch.watching?
    end
  end

  test "not_watching scope returns only not watching records" do
    # First create a not watching record
    watch = Watch.create!(card: cards(:buy_domain), user: users(:david), watching: false)

    not_watching_watches = Watch.not_watching
    assert_includes not_watching_watches, watch
    not_watching_watches.each do |w|
      assert_not w.watching?
    end
  end

  test "touches card when created" do
    card = cards(:buy_domain)
    original_updated_at = card.updated_at

    travel 1.minute do
      Watch.create!(card: card, user: users(:jz), watching: true)
      assert card.reload.updated_at > original_updated_at
    end
  end

  test "touches card when updated" do
    watch = watches(:logo_david)
    card = watch.card
    original_updated_at = card.updated_at

    travel 1.minute do
      watch.update!(watching: false)
      assert card.reload.updated_at > original_updated_at
    end
  end

  test "touches card when destroyed" do
    watch = watches(:logo_david)
    card = watch.card
    original_updated_at = card.updated_at

    travel 1.minute do
      watch.destroy
      assert card.reload.updated_at > original_updated_at
    end
  end

  test "user can watch multiple cards" do
    user = users(:david)
    watched_cards = user.watches.watching.map(&:card)
    assert_operator watched_cards.count, :>=, 2
  end

  test "card can be watched by multiple users" do
    card = cards(:logo)
    watchers = card.watches.watching.map(&:user)
    assert_operator watchers.count, :>=, 2
    assert_includes watchers, users(:david)
    assert_includes watchers, users(:kevin)
  end
end

require "test_helper"

class TaggingTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "belongs to account, tag, and card" do
    tagging = taggings(:logo_web)
    assert_equal accounts("37s"), tagging.account
    assert_equal tags(:web), tagging.tag
    assert_equal cards(:logo), tagging.card
  end

  test "creates tagging with default account from card" do
    tagging = Tagging.create!(card: cards(:logo), tag: tags(:mobile))
    assert_equal cards(:logo).account, tagging.account
  end

  test "touches card when created" do
    card = cards(:buy_domain)
    original_updated_at = card.updated_at

    travel 1.minute do
      Tagging.create!(card: card, tag: tags(:web))
      assert card.reload.updated_at > original_updated_at
    end
  end

  test "touches card when destroyed" do
    tagging = taggings(:logo_web)
    card = tagging.card
    original_updated_at = card.updated_at

    travel 1.minute do
      tagging.destroy
      assert card.reload.updated_at > original_updated_at
    end
  end

  test "card can have multiple taggings" do
    card = cards(:layout)
    assert_operator card.taggings.count, :>=, 2
    assert_includes card.tags, tags(:web)
    assert_includes card.tags, tags(:mobile)
  end

  test "tag can have multiple taggings" do
    tag = tags(:web)
    assert_operator tag.taggings.count, :>=, 2
  end

  test "tagging connects card and tag" do
    card = cards(:logo)
    tag = tags(:web)

    tagging = card.taggings.find_by(tag: tag)
    assert tagging.present?
    assert_equal card, tagging.card
    assert_equal tag, tagging.tag
  end
end

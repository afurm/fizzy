require "test_helper"

class MentionTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "belongs to account, source, mentioner, and mentionee" do
    mention = mentions(:logo_card_david_mention_by_jz)
    assert_equal accounts("37s"), mention.account
    assert_equal cards(:logo), mention.source
    assert_equal users(:jz), mention.mentioner
    assert_equal users(:david), mention.mentionee
  end

  test "creates mention with default account from source" do
    mention = Mention.create!(
      source: cards(:logo),
      mentioner: users(:kevin),
      mentionee: users(:david)
    )
    assert_equal cards(:logo).account, mention.account
  end

  test "source can be a Card" do
    mention = mentions(:logo_card_david_mention_by_jz)
    assert_instance_of Card, mention.source
  end

  test "source can be a Comment" do
    mention = mentions(:logo_comment_david_mention_by_jz)
    assert_instance_of Comment, mention.source
  end

  test "self_mention? returns true when mentioner equals mentionee" do
    mention = Mention.new(
      source: cards(:logo),
      mentioner: users(:david),
      mentionee: users(:david)
    )
    assert mention.self_mention?
  end

  test "self_mention? returns false when mentioner differs from mentionee" do
    mention = mentions(:logo_card_david_mention_by_jz)
    assert_not mention.self_mention?
  end

  test "delegates card to source" do
    card_mention = mentions(:logo_card_david_mention_by_jz)
    assert_equal cards(:logo), card_mention.card

    comment_mention = mentions(:logo_comment_david_mention_by_jz)
    assert_equal cards(:logo), comment_mention.card
  end

  test "notifiable_target returns source" do
    mention = mentions(:logo_card_david_mention_by_jz)
    assert_equal mention.source, mention.notifiable_target
  end

  test "watches source by mentionee after create" do
    card = cards(:buy_domain)
    mentionee = users(:jz)

    # Ensure the user isn't already watching
    card.watches.where(user: mentionee).destroy_all

    assert_difference -> { card.watches.count }, 1 do
      Mention.create!(
        source: card,
        mentioner: users(:david),
        mentionee: mentionee
      )
    end

    watch = card.watches.find_by(user: mentionee)
    assert watch.watching?
  end
end

require "test_helper"

class BoardTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "belongs to creator and account" do
    board = boards(:writebook)
    assert_equal users(:david), board.creator
    assert_equal accounts("37s"), board.account
  end

  test "creates board with default account from creator" do
    board = Board.create!(name: "New Board", creator: users(:david))
    assert_equal users(:david).account, board.account
  end

  test "has many cards through board" do
    board = boards(:writebook)
    assert_includes board.cards, cards(:logo)
    assert_includes board.cards, cards(:layout)
  end

  test "has many events" do
    board = boards(:writebook)
    assert board.events.any?
    assert_includes board.events, events(:logo_published)
  end

  test "has many tags through cards" do
    board = boards(:writebook)
    assert_includes board.tags, tags(:web)
    assert_includes board.tags, tags(:mobile)
  end

  test "alphabetically scope orders by lowercase name" do
    board_a = Board.create!(name: "Alpha", creator: users(:david))
    board_z = Board.create!(name: "Zulu", creator: users(:david))

    boards = Board.where(id: [ board_a.id, board_z.id ]).alphabetically
    assert_equal [ board_a, board_z ], boards.to_a
  end

  test "all_access determines board accessibility" do
    assert boards(:writebook).all_access?
    assert_not boards(:private).all_access?
  end

  test "has rich text public_description" do
    board = boards(:writebook)
    board.public_description = "This is a **public** description"
    board.save!

    assert_equal "This is a **public** description", board.reload.public_description.to_plain_text.strip
  end

  test "destroying board destroys associated webhooks" do
    board = boards(:writebook)
    webhook = board.webhooks.create!(name: "Test Webhook", url: "https://example.com/webhook", account: board.account)
    webhook_id = webhook.id

    board.destroy

    assert_nil Webhook.find_by(id: webhook_id)
  end
end

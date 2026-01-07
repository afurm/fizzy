require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "belongs to account, board, creator, and eventable" do
    event = events(:logo_published)
    assert_equal accounts("37s"), event.account
    assert_equal boards(:writebook), event.board
    assert_equal users(:david), event.creator
    assert_equal cards(:logo), event.eventable
  end

  test "creates event with default account from board" do
    card = cards(:logo)
    event = Event.create!(
      board: card.board,
      creator: users(:david),
      eventable: card,
      action: "card_updated"
    )
    assert_equal card.board.account, event.account
  end

  test "action returns an inquiry object" do
    event = events(:logo_published)
    assert event.action.card_published?
    assert_not event.action.card_closed?
  end

  test "chronologically scope orders by created_at asc" do
    board = boards(:writebook)
    events = board.events.chronologically
    assert events.first.created_at <= events.last.created_at
  end

  test "delegates card to eventable" do
    event = events(:logo_published)
    assert_equal cards(:logo), event.card
  end

  test "description_for returns Event::Description" do
    event = events(:logo_published)
    description = event.description_for(users(:david))
    assert_instance_of Event::Description, description
  end

  test "notifiable_target returns eventable" do
    event = events(:logo_published)
    assert_equal event.eventable, event.notifiable_target
  end

  test "dispatches webhooks after create" do
    card = cards(:logo)

    assert_enqueued_with(job: Event::WebhookDispatchJob) do
      Event.create!(
        board: card.board,
        creator: users(:david),
        eventable: card,
        action: "card_updated"
      )
    end
  end

  test "has many webhook_deliveries" do
    event = events(:logo_published)
    assert_respond_to event, :webhook_deliveries
  end

  test "destroying event deletes associated webhook deliveries" do
    event = events(:logo_published)
    webhook = event.board.webhooks.create!(name: "Test Webhook", url: "https://example.com/webhook", account: event.account)
    delivery = event.webhook_deliveries.create!(webhook: webhook, account: event.account)
    delivery_id = delivery.id

    event.destroy

    assert_nil Webhook::Delivery.find_by(id: delivery_id)
  end
end

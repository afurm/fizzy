require "test_helper"

class StepTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "belongs to account and card" do
    card = cards(:logo)
    step = Step.create!(card: card, content: "First step")
    assert_equal card.account, step.account
    assert_equal card, step.card
  end

  test "creates step with default account from card" do
    card = cards(:logo)
    step = Step.create!(card: card, content: "New step")
    assert_equal card.account, step.account
  end

  test "validates presence of content" do
    step = Step.new(card: cards(:logo))
    assert_not step.valid?
    assert_includes step.errors[:content], "can't be blank"
  end

  test "completed scope returns only completed steps" do
    card = cards(:logo)
    completed_step = Step.create!(card: card, content: "Done", completed: true)
    incomplete_step = Step.create!(card: card, content: "Todo", completed: false)

    assert_includes Step.completed, completed_step
    assert_not_includes Step.completed, incomplete_step
  end

  test "completed? returns completion status" do
    card = cards(:logo)
    completed_step = Step.create!(card: card, content: "Done", completed: true)
    incomplete_step = Step.create!(card: card, content: "Todo", completed: false)

    assert completed_step.completed?
    assert_not incomplete_step.completed?
  end

  test "touches card when created" do
    card = cards(:logo)
    original_updated_at = card.updated_at

    travel 1.minute do
      Step.create!(card: card, content: "New step")
      assert card.reload.updated_at > original_updated_at
    end
  end

  test "touches card when updated" do
    card = cards(:logo)
    step = Step.create!(card: card, content: "A step")
    original_updated_at = card.updated_at

    travel 1.minute do
      step.update!(completed: true)
      assert card.reload.updated_at > original_updated_at
    end
  end

  test "touches card when destroyed" do
    card = cards(:logo)
    step = Step.create!(card: card, content: "A step")
    original_updated_at = card.updated_at

    travel 1.minute do
      step.destroy
      assert card.reload.updated_at > original_updated_at
    end
  end
end

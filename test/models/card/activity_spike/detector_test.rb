require "test_helper"

class Card::ActivitySpike::DetectorTest < ActiveSupport::TestCase
  include CardActivityTestHelper

  setup do
    Current.session = sessions(:david)
    @card = cards(:logo)
  end

  test "detect multiple people commenting" do
    assert_activity_spike_detected do
      multiple_people_comment_on(@card)
    end
  end

  test "detect assignments" do
    assert_activity_spike_detected do
      @card.toggle_assignment users(:kevin)
    end
  end

  test "refresh the activity spike on new spikes" do
    multiple_people_comment_on(@card)

    @card = Card.find(@card.id)

    original_last_spike_at = @card.activity_spike.updated_at
    travel 2.months

    multiple_people_comment_on(@card.reload)

    assert @card.reload.activity_spike.updated_at > original_last_spike_at
  end

  private
    def assert_activity_spike_detected(card: @card)
      assert card.activity_spike.blank?
      perform_enqueued_jobs only: Card::ActivitySpike::DetectionJob do
        yield
      end
      assert card.reload.activity_spike.present?
    end
end

class Prompts::CardsController < ApplicationController
  MAX_RESULTS = 10

  def index
    @cards = if filter_param.present?
      prepending_exact_matches_by_id(published_cards.mentioning(params[:filter]))
    else
      @cards = published_cards.latest
    end

    if stale? etag: @cards
      render layout: false
    end
  end

  private
    def filter_param
      params[:filter]
    end

    def published_cards
      Current.user.accessible_cards.published.limit(MAX_RESULTS)
    end

    def prepending_exact_matches_by_id(cards)
      if card_by_id = Current.user.accessible_cards.find_by_id(params[:filter])
        [card_by_id] + cards
      else
        cards
      end
    end
end

class Search::Query < ApplicationRecord
  validates :terms, presence: true
  before_validation :sanitize_query_syntax

  class << self
    def wrap(query)
      if query.is_a?(self)
        query
      else
        self.new(terms: query)
      end
    end
  end

  alias_attribute :to_s, :terms

  private
    def sanitize_query_syntax
      self.terms = begin
        terms = remove_invalid_search_characters(self.terms)
        terms = remove_unbalanced_quotes(terms)
        terms.presence
      end
    end

    def remove_invalid_search_characters(terms)
      terms.gsub(/[^\w"]/, " ")
    end

    def remove_unbalanced_quotes(terms)
      if terms.count("\"").even?
        terms
      else
        terms.gsub("\"", " ")
      end
    end
end

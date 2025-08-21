class User::Filtering
  attr_reader :user, :filter, :expanded

  delegate :as_params, to: :filter

  def initialize(user, filter, expanded: false)
    @user, @filter, @expanded = user, filter, expanded
  end

  def collections
    @collections ||= user.collections.ordered_by_recently_accessed
  end

  def collections_title
    if filter.collections.none?
      collections.one? ? collections.first.name : "All collections"
    elsif filter.collections.one?
      filter.collections.first.name
    else
      filter.collections.map(&:name).to_sentence
    end
  end

  def tags
    @tags ||= Tag.all.alphabetically
  end

  def users
    @users ||= User.active.alphabetically
  end

  def filters
    @filters ||= Current.user.filters.all
  end

  def expanded?
    @expanded
  end

  def any?
    filter.tags.any? || filter.assignees.any? || filter.creators.any? || filter.closers.any? ||
      filter.stages.any? || filter.terms.any? || filter.card_ids&.any? ||
      filter.assignment_status.unassigned? || !filter.indexed_by.latest?
  end

  def show_indexed_by?
    expanded? || !filter.indexed_by.latest?
  end

  def show_tags?
    expanded? || filter.tags.any?
  end

  def show_assignees?
    expanded? || filter.assignees.any?
  end

  def show_creators?
    expanded? || filter.creators.any?
  end

  def show_closers?
    expanded? || filter.closers.any?
  end

  def show_time_window?(name)
    expanded? || filter.public_send("#{name}_window").present?
  end
end

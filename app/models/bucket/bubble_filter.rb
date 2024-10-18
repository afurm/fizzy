class Bucket::BubbleFilter
  def initialize(bucket, params = {})
    @bucket = bucket
    @status = params["status"]
    @order_by = params["order_by"]
    @term = params["term"]
    @tag_ids = params["tag_ids"]
    @assignee_ids = params["assignee_ids"]
  end

  def bubbles
    @bubbles ||= begin
      result = bucket.bubbles
      result = result.ordered_by(order_by || Bubble.default_order_by)
      result = result.with_status(status || Bubble.default_status)
      result = result.tagged_with(tags) if tags
      result = result.assigned_to(assignees) if assignees
      result = result.mentioning(term) if term
      result
    end
  end

  def tags
    @tags ||= account.tags.where(id: tag_ids) if tag_ids
  end

  def assignees
    @assignees ||= account.users.where(id: assignee_ids) if assignee_ids
  end

  private
    attr_reader :bucket, :status, :order_by, :term, :tag_ids, :assignee_ids
    delegate :account, to: :bucket, private: true
end

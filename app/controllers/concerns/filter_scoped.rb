module FilterScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_filter
    before_action :set_user_filtering
  end

  private
    DEFAULT_PARAMS = { indexed_by: "latest" }

    def set_filter
      if params[:filter_id].present?
        @filter = Current.user.filters.find(params[:filter_id])
      else
        @filter = Current.user.filters.from_params params.reverse_merge(**DEFAULT_PARAMS).permit(*Filter::PERMITTED_PARAMS)
      end
    end

    def set_user_filtering
      @user_filtering = User::Filtering.new(Current.user, @filter, expanded: params[:expand_all])
    end
end

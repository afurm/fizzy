class SearchesController < ApplicationController
  def create
    Current.user.remember_search(query_param)
    head :ok
  end

  def show
    @search_results = Current.user.search(query_param, max_results: 50)
    @recent_search_queries = Current.user.search_queries.order(created_at: :desc).limit(10)
  end

  private
    def query_param
      params[:q]
    end
end

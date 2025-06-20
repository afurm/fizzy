class Prompts::Collections::UsersController < ApplicationController
  include CollectionScoped

  def index
    @users = @collection.users

    if stale? etag: @users
      render layout: false
    end
  end
end

class PagesController < ApplicationController
  allow_unauthenticated_access only: :home

  def home
  end

  def profile
    @current_user = Current.user
  end
end

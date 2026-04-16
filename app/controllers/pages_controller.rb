class PagesController < ApplicationController
  allow_unauthenticated_access only: :home

  before_action :set_locale_if_unauthenticated, only: :home

  def home
    redirect_to sensors_path if authenticated?
  end
end

class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  # Public landing page; signed-in agents go straight to their dashboard
  def home
    redirect_to dashboard_path if user_signed_in?
  end
end

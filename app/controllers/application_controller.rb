class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :maintanence_mode

  # TODO: remove once we upgrade Rails and so on.
  def maintanence_mode
    render(partial: 'maintenance')
  end
end

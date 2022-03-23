class PingController < ApplicationController

  def index
    Rails.logger.silence do
      head :no_content
    end
  end
end
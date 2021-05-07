class SpeciesController < ApplicationController
  def self.request_time
    @request_time ||= DateTime.now
  end

  def index
    if stale?(last_modified: SpeciesController.request_time)
      render json: Rails.cache.fetch('species_index') {  {"data": Species.taxons }.as_json }
    end
  end
end

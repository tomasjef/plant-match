class PlantsController < ApplicationController
  RESULT_LIMIT = 9

  skip_before_action :authenticate_user!, only: %i[index show results]

  def index
    @plants = indoor_plants
  end

  # Perenual's matches first, topped up with the best saved plants
  def results
    remember_match_params
    @plants = perenual_matches + indoor_plants.to_a
    score_plants
  end

  def show
    @plant = Plant.find(params[:id])
    @back_to_matches_path = plant_matches_path(session[:plant_match_params] || {})
    sync_perenual_details(@plant)

    @plant_info = @plant.description.presence || @plant.plant_info.presence

    return unless user_signed_in?

    @chat = current_user.chats.find_or_create_by!(plant: @plant)
    @message = Message.new
  end

  private

  def indoor_plants
    Plant.displayable.where(indoor_outdoor: %w[indoor both])
  end

  def perenual_client
    Perenual::Client.new
  end

  def perenual_matches
    Perenual::MatchPlants.new(params: params).call
  rescue StandardError => e
    Rails.logger.warn("Perenual search failed: #{e.class} - #{e.message}")
    []
  end

  def remember_match_params
    session[:plant_match_params] = params.permit(
      :light_needs,
      :water_needs,
      :care_level,
      :pet_safe
    ).to_h
  end

  def sync_perenual_details(plant)
    return if plant.perenual_id.blank?
    return if plant.description.present? && plant.synced_at.present? && plant.synced_at > 7.days.ago

    details = perenual_client.species_details(plant.perenual_id)
    Perenual::ImportPlant.new(details).call
  rescue StandardError => e
    Rails.logger.warn("Perenual detail sync failed for plant #{plant.id}: #{e.class} - #{e.message}")
  end

  def score_plants
    scored_plants = @plants.each_with_index.map do |plant, index|
      { plant: plant, score: score_for(plant), index: index }
    end

    @plants = scored_plants
              .sort_by { |item| [-item[:score], item[:index]] }
              .uniq { |item| plant_identity(item[:plant]) }
              .first(RESULT_LIMIT)
  end

  def plant_identity(plant)
    normalized_name(plant.scientific_name).presence || normalized_name(plant.name)
  end

  def normalized_name(name)
    name.to_s.downcase.gsub(/[^a-z0-9]+/, " ").squish
  end

  def score_for(plant)
    string_criteria = %i[light_needs water_needs care_level]
    string_score = string_criteria.count do |attribute|
      params[attribute].present? && plant.public_send(attribute) == params[attribute]
    end

    string_score + boolean_score_for(plant, :pet_safe)
  end

  def boolean_score_for(plant, attribute)
    return 0 unless params[attribute].present?

    plant.public_send(attribute) == (params[attribute] == "true") ? 1 : 0
  end
end

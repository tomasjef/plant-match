class PlantsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show results]

  def index
    @plants = indoor_plants
  end

  def results
    @plants = indoor_plants
    score_plants
  end

  def show
    @plant = Plant.find(params[:id])

    if @plant.plant_info.blank?
      response = generate_plant_info(@plant)
      @plant.update(plant_info: response)
    end

    @plant_info = @plant.plant_info.presence ||
                  "Plant care information is not available yet. Please try again later."
  end

  private

  def indoor_plants
    Plant.where(indoor_outdoor: %w[indoor both])
  end

  def generate_plant_info(plant)
    RubyLLM.chat
           .with_instructions("You are a plant expert. Be concise and informative.")
           .ask("For a #{plant.name} plant, give me:
      1. Care tips
      2. A short history of this plant
      3. A common illness for this plant and the method of treatment")
           .content
  rescue StandardError => e
    Rails.logger.warn("Plant info generation failed for plant #{plant.id}: #{e.class} - #{e.message}")
    nil
  end

  def score_plants
    scored_plants = @plants.map { |plant| { plant: plant, score: score_for(plant) } }

    @plants = scored_plants.sort_by { |item| -item[:score] }.first(6)
  end

  def score_for(plant)
    string_criteria = %i[light_needs water_needs care_level growth_style]
    string_score = string_criteria.count do |attribute|
      params[attribute].present? && plant.public_send(attribute) == params[attribute]
    end

    string_score + boolean_score_for(plant, :pet_safe) + boolean_score_for(plant, :air_purifying)
  end

  def boolean_score_for(plant, attribute)
    return 0 unless params[attribute].present?

    plant.public_send(attribute) == (params[attribute] == "true") ? 1 : 0
  end
end

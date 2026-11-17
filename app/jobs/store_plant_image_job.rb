class StorePlantImageJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound

  def perform(plant_id)
    plant = Plant.find(plant_id)
    return if plant.stored_image_url.present? || !ImageStore.configured?

    source = plant.api_image_url.presence || plant.image_url
    return if source.blank? || Plant.expired_link?(source)

    url = ImageStore.new.upload(source, public_id: "plant-match/perenual-#{plant.perenual_id || "plant-#{plant.id}"}")
    plant.update_columns(stored_image_url: url)
  rescue StandardError => e
    # The next import of this plant tries again
    Rails.logger.warn("Plant image copy failed for plant #{plant_id}: #{e.class} - #{e.message}")
  end
end

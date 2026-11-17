namespace :plants do
  desc "Copy every plant photo to Cloudinary, refreshing expired Perenual links first"
  task store_images: :environment do
    abort "Set CLOUDINARY_URL first." unless ImageStore.configured?

    # Copies happen here, one by one, rather than in the background
    ActiveJob::Base.queue_adapter = :inline
    client = Perenual::Client.new

    Plant.where(stored_image_url: [nil, ""]).find_each do |plant|
      next puts("locked to paid Perenual plans: #{plant.name}") if plant.locked?

      # Only for dead links, to spare the Perenual quota; descriptions load when a plant is opened
      Perenual::ImportPlant.new(client.species_details(plant.perenual_id)).call if plant.image_expired?
      StorePlantImageJob.perform_now(plant.id)
      puts "#{plant.reload.stored_image_url.present? ? 'copied' : 'not copied'}: #{plant.name}"
    rescue StandardError => e
      puts "failed: #{plant.name} (#{e.message})"
    end
  end
end

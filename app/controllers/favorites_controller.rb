class FavoritesController < ApplicationController
  # Nur eingeloggte User dürfen Pflanzen speichern
  before_action :authenticate_user!

  # User Story 4: Liste meiner Favoriten ("My Garden")
  def index
    @favorites = current_user.favorites
  end

  # User Story 3: Pflanze speichern
  def create
    @plant = Plant.find(params[:plant_id])
    # Wir erstellen die Verknüpfung
    @favorite = Favorite.new(user: current_user, plant: @plant)

    if @favorite.save
      redirect_back fallback_location: plant_matches_path, notice: "#{@plant.display_name} saved to My Plants."
    else
      # Falls der User die Pflanze schon hat (Validierung), zurück zum Index
      redirect_back fallback_location: my_plants_path, alert: "Already in My Plants."
    end
  end

  # Bonus: Favorit entfernen
  def destroy
    @favorite = current_user.favorites.find(params[:id])
    @favorite.destroy
    redirect_to my_plants_path, status: :see_other, notice: "Removed from My Plants."
  end
end

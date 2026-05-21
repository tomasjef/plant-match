Rails.application.routes.draw do
  devise_for :users, path: "account", path_names: {
    sign_in: "log-in",
    sign_out: "log-out",
    sign_up: "sign-up",
    password: "password"
  }

  post "plants/:plant_id/assistant/messages",
     to: "messages#create",
     as: :plant_assistant_messages

  root to: "pages#home"

  get "find-a-plant", to: "chats#new", as: :find_plant
  get "plant-matches", to: "plants#results", as: :plant_matches

  get "browse-plants", to: "plants#index", as: :browse_plants
  get "plants/:id", to: "plants#show", as: :plant
  post "plants/:plant_id/save", to: "favorites#create", as: :save_plant

  get "my-plants", to: "favorites#index", as: :my_plants
  delete "my-plants/:id", to: "favorites#destroy", as: :saved_plant
end

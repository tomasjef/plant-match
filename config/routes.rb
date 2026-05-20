Rails.application.routes.draw do
  devise_for :users, path: "account", path_names: {
    sign_in: "log-in",
    sign_out: "log-out",
    sign_up: "sign-up",
    password: "password"
  }

  root to: "pages#home"

  get "find-a-plant", to: "chats#new", as: :find_plant
  get "plant-matches", to: "plants#results", as: :plant_matches

  get "browse-plants", to: "plants#index", as: :browse_plants
  get "plants/:id", to: "plants#show", as: :plant
  post "plants/:plant_id/save", to: "favorites#create", as: :save_plant

  get "my-plants", to: "favorites#index", as: :my_plants
  delete "my-plants/:id", to: "favorites#destroy", as: :saved_plant

  post "plant-assistant", to: "chats#create", as: :plant_chats
  get "plant-assistant/:id", to: "chats#show", as: :plant_chat
  post "plant-assistant/:chat_id/messages", to: "messages#create", as: :plant_chat_messages
end

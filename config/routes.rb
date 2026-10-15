Rails.application.routes.draw do
  get "messages/create"
  get "chats/create"
  get "chats/show"
  devise_for :users
  root to: "pages#home"

  resources :properties do
    member do
      delete :remove_involved_party
    end
  end

  resources :transactions do
    member do
      delete :remove_involved_party
    end
  end

  resources :involved_parties do
    member do
      post :assign_property
      delete "unassign_property/:property_id", action: :unassign_property, as: :unassign_property
      post :assign_transaction
      delete "unassign_transaction/:transaction_id", action: :unassign_transaction, as: :unassign_transaction
    end
  end

  resources :chains

  resources :chats, only: :show do
    resources :messages, only: [:create]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end

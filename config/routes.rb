Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # Agent profiles (declared after Devise so /users/sign_in etc. still reach Devise)
  resources :users, only: :show

  # Signed-in home for agents
  get "dashboard", to: "dashboards#show", as: :dashboard

  # Guided "new sale" flow: vendor → property → buyer → chain
  resource :sale, only: [:new, :create]

  resources :properties do
    member do
      delete :remove_involved_party
    end
  end

  resources :transactions do
    member do
      delete :remove_involved_party
      patch :update_stage
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

  resources :chains do
    member do
      post :merge
      post :connect_property
    end
  end

  resources :chats, only: :show do
    resources :messages, only: [:create]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # mission control of jobs for our admin users
  authenticate :user, ->(user) { user.admin? } do
  mount MissionControl::Jobs::Engine, at: "/jobs"
end
end

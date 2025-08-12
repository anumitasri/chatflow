Rails.application.routes.draw do
  # Devise (using your custom controllers under app/controllers/users/)
  devise_for :users,
             controllers: {
               registrations: 'users/registrations',
               sessions: 'users/sessions'
             }

  # Profile
  get  "/users/me", to: "users#me"
  put  "/users/me", to: "users#update"
  # Health / PWA (keep if you use them)
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest


  # Chat management + messaging
  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:index, :create]
  end

  # Action Cable (real-time)
  mount ActionCable.server => '/cable'

  # Web UI home
  root "conversations#index"
end

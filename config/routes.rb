Rails.application.routes.draw do
  mount RailsIcons::Engine, at: '/rails_icons'

  get 'manifest.json', to: 'rails/pwa#manifest', as: :pwa_manifest, defaults: { format: :json }
  get 'service-worker.js', to: 'rails/pwa#service_worker', as: :pwa_service_worker,
                              defaults: { format: :js }

  resource :session, only: %i[new create destroy]
  resources :passwords, only: %i[new create edit update], param: :token
  resources :registrations, only: %i[new create]
  resources :plants, only: %i[] do
    collection do
      get :search
      post :prepare
    end
  end

  namespace :sensors do
    resource :setup, controller: :setup, only: %i[new create] do
      get :validate_uid, on: :member
    end
  end

  namespace :api do
    namespace :v1 do
      resource :measurements, only: [:update]
    end
  end

  root 'pages#home'

  get 'profile', to: 'pages#profile'
  patch 'profile/locale', to: 'pages#update_locale', as: :profile_locale
end

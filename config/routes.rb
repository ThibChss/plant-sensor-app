Rails.application.routes.draw do
  mount RailsIcons::Engine, at: '/rails_icons'

  get 'manifest.json', to: 'rails/pwa#manifest', as: :pwa_manifest, defaults: { format: :json }
  get 'service-worker.js', to: 'rails/pwa#service_worker', as: :pwa_service_worker,
                              defaults: { format: :js }

  root 'pages#home'

  resource :session, only: %i[new create destroy]
  resources :passwords, only: %i[new create edit update], param: :token
  resources :registrations, only: %i[new create]

  resources :plants, only: %i[] do
    collection do
      get :search
      post :prepare
    end
  end

  resources :sensors, only: %i[index show] do
    resources :readings, only: %i[index], path: :sensor_readings, module: :sensors,
                         controller: :sensor_readings
  end

  namespace :sensors do
    resource :setup, controller: :setup, only: %i[new create] do
      patch :validate_uid, on: :member
    end
  end

  namespace :users do
    resources :push_subscriptions, only: %i[create]
    resource :presence, only: %i[update], controller: :presence
  end

  namespace :api do
    namespace :v1 do
      resource :measurements, only: [:update]
      resource :connection, only: [:update], controller: :connection
    end
  end

  resource :profile, controller: :profile, only: [:show] do
    patch :update_locale, on: :member, as: :locale
    patch :update_push_notifications, on: :member, as: :push_notifications
  end
end

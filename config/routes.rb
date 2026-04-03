Rails.application.routes.draw do
  mount RailsIcons::Engine, at: '/rails_icons'

  get 'manifest.json', to: 'rails/pwa#manifest', as: :pwa_manifest, defaults: { format: :json }
  get 'service-worker.js', to: 'rails/pwa#service_worker', as: :pwa_service_worker,
                              defaults: { format: :js }

  resource :session, only: %i[new create destroy]
  resources :passwords, only: %i[new create edit update], param: :token
  resources :registrations, only: %i[new create]

  root 'pages#home'

  get 'profile', to: 'pages#profile'
end

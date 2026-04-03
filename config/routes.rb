Rails.application.routes.draw do
  mount RailsIcons::Engine, at: '/rails_icons'

  resource :session, only: %i[new create destroy]
  resources :passwords, only: %i[new create edit update], param: :token
  resources :registrations, only: %i[new create]

  root 'pages#home'

  get 'profile', to: 'pages#profile'
end

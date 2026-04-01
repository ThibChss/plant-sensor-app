Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  resources :passwords, only: %i[new create edit update], param: :token
  resources :registrations, only: %i[new create]

  root 'pages#home'
end

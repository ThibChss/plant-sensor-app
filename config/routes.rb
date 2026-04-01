Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  resources :passwords, only: %i[new create edit update], param: :token

  root 'pages#home'
end

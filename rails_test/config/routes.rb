Rails.application.routes.draw do
  root "home#index"
  resources :user
  resources :note
end

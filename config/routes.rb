Rails.application.routes.draw do
  get '/dashboard' => 'dashboard#index', as: :dashboard

  resources :properties
  devise_for :accounts
  root to: 'public#main'
  # devise_scope :account do
  #   get 'sign_in', to: 'devise/sessions#new'
  # end
end

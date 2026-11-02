Rails.application.routes.draw do
  get "/healthz", to: "health#show", as: :healthz


  devise_for :accounts, controllers: { registrations: "accounts/registrations" }
  resources :posts
  get '/my/properties', to: 'properties#mine', as: :my_properties
  resources :properties

  get '/blog' => 'posts#latest', as: :blog

  get '/accounts' => 'admin#accounts', as: :accounts

  get '/dashboard' => 'dashboard#index', as: :dashboard
  get '/profile/:id' => 'dashboard#profile', as: :profile
  post 'agent/message' => "properties#email_agent", as: :email_agent
  post "/profile/:profile_id/message" => "agent_messages#create", as: :profile_email_agent
  patch "/agent_messages/:id" => "agent_messages#update", as: :agent_message
  resources :enquiries, only: [:create, :index, :update]


  root to: 'public#main'

end

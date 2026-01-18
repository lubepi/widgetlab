Rails.application.routes.draw do
  # OmniAuth/Keycloak Authentifizierung
  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  get "/login", to: "sessions#new", as: :login
  match "/logout", to: "sessions#destroy", as: :logout, via: [:get, :delete]

  resources :data_source_whitelists
  resources :widget_data_source_transformers
  resources :data_sources, only: %i[index show create edit update destroy] do
    collection do
      get :config_fields
      post :start_all_subscriptions
    end
    member do
      post :start_subscription
      post :stop_subscription
      get :whitelist, to: "data_source_whitelists#edit"
      patch :whitelist, to: "data_source_whitelists#update"
      get :latest_response
    end
  end
  resources :dashboard_widgets
  resources :user_widget_roles
  resources :widgets do
    member do
      get :access, to: "user_widget_roles#edit"
      patch :access, to: "user_widget_roles#update"
      get :add_to_dashboard # Modal zum Auswählen des Dashboards
      post :add_to_dashboard, action: :create_on_dashboard # Widget zu Dashboard hinzufügen
    end
  end
  resources :user_group_roles
  resources :user_groups, only: %i[index show new create edit update destroy]
  resources :dashboard_user_roles
  resources :dashboards do
    member do
      get :access, to: "dashboard_user_roles#edit"
      patch :access, to: "dashboard_user_roles#update"
    end
    resources :dashboard_widgets, only: [:new, :create], controller: 'dashboard_widgets' do
      collection do
        patch :update_positions
        get :select_widget
      end
    end
  end
  resources :users, only: %i[index show]

  # Bootstrap Demo Seite
  get "bootstrap_demo", to: "pages#bootstrap_demo"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboards#index"
end

Rails.application.routes.draw do
  resources :data_source_whitelists
  resources :widget_data_source_transformers
  resources :data_sources do
    member do
      post :start_subscription
      post :stop_subscription
    end
  end
  resources :dashboard_widgets
  resources :user_widget_roles
  resources :widgets
  resources :user_group_roles
  resources :user_groups
  resources :dashboard_user_roles
  resources :dashboards
  resources :users

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
  # root "posts#index"
end

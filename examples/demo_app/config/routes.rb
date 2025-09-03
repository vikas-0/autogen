Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    resources :users, only: [:index, :show, :create]

    # Router-only: projects with custom member/collection actions and nested releases
    resources :projects, only: [] do
      member do
        get :summary
        post :archive
      end
      collection do
        get :search
      end

      resources :releases, only: [] do
        member do
          post :deploy
        end
      end
    end

    # Namespaced admin controller with collection route
    namespace :admin do
      resources :metrics, only: [] do
        collection do
          get :uptime
        end
      end
    end

    # Standalone custom routes for reports
    get "reports/:year/:month", to: "reports#monthly"
    post "reports/run", to: "reports#run"
  end
end

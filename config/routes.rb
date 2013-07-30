RailsGithubOauth::Application.routes.draw do
  root :to => "home#index"
  resources :users, :only => [:index, :show, :edit, :update ]
  match '/auth/:provider/callback' => 'sessions#create'
  match '/signin' => 'sessions#new', :as => :signin
  match '/signout' => 'sessions#destroy', :as => :signout
  match '/auth/failure' => 'sessions#failure'
  match '/coverage_reports' => 'coverage_viewer#view_coverage_list'
  get 'coverage_view/:sha/:filename.*ext', to: 'coverage_viewer#s3_streamer', format: false
end

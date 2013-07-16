Bugmetilidoit::Application.routes.draw do
  resources :assigned_networks
  
  resources :networks
  
  match 'assigned_tasks/:id/mark_completed' => 'assigned_tasks#update', as: :complete_assigned_task, via: :get
  
  resources :reminders

  resources :tasks

  authenticated :user do
    root :to => 'home#index'
  end
  root :to => "home#index"
  devise_for :users
  resources :users do
    resources :assigned_tasks
    member do
      get 'oauth'
      get 'twitter_oauth'
    end
  end
end
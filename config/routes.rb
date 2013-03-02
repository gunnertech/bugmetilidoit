Bugmetilidoit::Application.routes.draw do
  resources :reminders


  resources :tasks


  


  authenticated :user do
    root :to => 'home#index'
  end
  root :to => "home#index"
  devise_for :users
  resources :users do
    resources :assigned_tasks
  end
end
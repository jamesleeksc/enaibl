Rails.application.routes.draw do
  devise_for :users
  get 'api/eadaptor' => 'api#eadaptor'
  post 'api/eadaptor' => 'api#eadaptor'
  put 'api/eadaptor' => 'api#eadaptor'

  resources :organizations
  resources :client_accounts

  get 'import_orgs' => 'organization#import'

  root to: 'static#index'
end

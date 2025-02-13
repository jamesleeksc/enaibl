Rails.application.routes.draw do
  devise_for :users
  get 'api/eadaptor' => 'api#eadaptor'
  post 'api/eadaptor' => 'api#eadaptor'
  put 'api/eadaptor' => 'api#eadaptor'

  resources :organizations, except: [:show]
  resources :client_accounts
  resources :email
  resources :shipments
  resources :invoices

  get 'email_sync' => 'email#sync'

  get 'organizations/import' => 'organizations#import'
  get 'organizations/import_contacts' => 'organizations#import_contacts'
  post 'organizations/upload' => 'organizations#upload'
  post 'organizations/upload_contacts' => 'organizations#upload_contacts'

  post "google/auth", to: "google#auth"
  get "google/auth", to: "google#auth"

  post "oauth2callback", to: "google#auth"
  get "oauth2callback", to: "google#auth"

  post 'cargowise_shipment' => 'cargowise#create_shipment'

  root to: 'static#index'
end

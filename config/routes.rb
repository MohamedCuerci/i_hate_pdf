Rails.application.routes.draw do
  root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # Rotas específicas primeiro
  get 'pdf/dividir_pdf', to: 'pdf#new', defaults: { action_type: 'split' }, as: :split_pdf
  get 'pdf/juntar_pdf', to: 'pdf#new', defaults: { action_type: 'merge' }, as: :merge_pdf
  get 'pdf/comprimir_pdf', to: 'pdf#new', defaults: { action_type: 'compress' }, as: :compress_pdf
  # get 'pdf/convert', to: 'pdf#new', defaults: { action_type: 'convert' }, as: :convert_pdf
 
  get 'download_pdf', to: 'pdf#download_pdf', as: :download_pdf # cuida para baixar o arquivo
  get 'download', to: 'pdf#download', as: :download # apenas uma tela q sou redirecionado

  # Rota genérica depois
  resources :pdf, only: [ :create ]
end

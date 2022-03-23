Rails.application.routes.draw do
  get 'genes/multiple_symbols'

  get 'genes/product_and_symbol'

  get 'genes/product_without_symbol'
  get 'genes/all_symbols'

  get 'about' => 'pages#about'

  resources :searches, only: [:new, :create, :show] do
    collection do
      get 'taxon'
    end
  end

  resources :species, only: :index, defaults: { format: :json }

  root 'searches#new'

  get 'ping' => 'ping#index'
end

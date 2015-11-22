Rails.application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  post '/editaccount', to: 'account#edit'
  post '/deleteaccount', to: 'account#delete'
  
  root to: 'application#angular'

  post 'pusher/auth'

  scope '/api', :defaults => {:format => 'json'} do
    controller :account do
      post  'account/edit'          => :edit
      post  'account/delete'        => :delete
      get   'account/picture'       => :picture
      post  'account/new_picture'   => :new_picture
    end
    
    controller :game_room do
      get   'gameroom'              => :index
      post  'gameroom/create'       => :create
      post  'gameroom/:id/join'     => :join
      get   'gameroom/:id/players'  => :players
      post  'gameroom/:id/start'    => :start
      get   'gameroom/:id/round'    => :round
      post  'gameroom/:id/leave'    => :leave
      post  'gameroom/:id/message'  => :message
    end

    controller :round do
      post  'round/:id/hand'        => :hand
      post  'round/:id/turn'        => :turn
    end
  end


  # match "/game_room/:id" => "gameroom#join"

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end

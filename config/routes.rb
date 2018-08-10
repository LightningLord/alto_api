Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html


  resources :names, only: [:update, :show] do 
  end

  match '/annotate' => "names#annotate", via: [:post]
  match '/names' => 'names#destroy_all', via: [:delete]
end

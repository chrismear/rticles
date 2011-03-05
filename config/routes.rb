Rticles::Application.routes.draw do
  resources :documents do
    resources :paragraphs do
      member do
        post 'indent'
        post 'outdent'
        post 'move_higher'
        post 'move_lower'
      end
    end
  end
  
  root :to => 'documents#index'
end

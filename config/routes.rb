Rticles::Application.routes.draw do
  resources :documents do
    resources :paragraphs do
      member do
        post 'indent'
        post 'outdent'
      end
    end
  end
  
  root :to => 'documents#index'
end

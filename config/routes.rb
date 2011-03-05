Rticles::Application.routes.draw do
  resources :documents do
    resources :paragraphs do
      
    end
  end
  
  root :to => 'documents#index'
end

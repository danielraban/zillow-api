Rails.application.routes.draw do
  match '/search' => 'search#search', via: [ :get, :post ], as: :search
  root to: 'search#search'
end

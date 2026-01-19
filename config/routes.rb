# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
#
#

resources :projects do  
  post 'report/update_page', to: 'report#update_page'
end

# My page 정렬 업데이트용 라우트
post 'my/update_page_sc_report', to: 'my#update_page_sc_report'


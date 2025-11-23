# agritrust_app/urls.py
from django.urls import path
from . import views

urlpatterns = [
    # HTML Template Routes
    path('', views.landing_page, name='landing-page'),
    path('register/', views.register_page, name='register-page'),
    path('login/', views.login_page, name='login-page'),
    path('produce/', views.produce_list_page, name='produce-list-page'),
    path('farmer/dashboard/', views.farmer_dashboard_page, name='farmer-dashboard-page'),
    path('orders/create/<int:produce_id>/', views.create_order_page, name='create-order-page'),
    path('market/analytics/', views.market_analytics_page, name='market-analytics-page'),
    path('gis/farms-map/', views.farms_map_page, name='farms-map-page'),
    path('add-produce/', views.add_produce_page, name='add-produce-page'),
    
    # API Routes
    path('api/register/', views.register_user, name='register-api'),
    path('api/login/', views.login_user, name='login-api'),
    path('api/logout/', views.logout_user, name='logout-api'),
    path('api/orders/create/', views.create_order_api, name='create-order-api'),
    path('api/produce/add/', views.add_produce_api, name='add-produce-api'),
    

]
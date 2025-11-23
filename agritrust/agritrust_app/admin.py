# admin.py
from django.contrib import admin
from .models import UserProfile, Produce, Order, MarketData, WeatherData

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'user_type', 'location', 'verified', 'created_at']
    list_filter = ['user_type', 'verified']
    search_fields = ['user__username', 'location']

@admin.register(Produce)
class ProduceAdmin(admin.ModelAdmin):
    list_display = ['name', 'farmer', 'produce_type', 'quantity', 'price_per_unit', 'quality_grade', 'available']
    list_filter = ['produce_type', 'quality_grade', 'available']
    search_fields = ['name', 'farmer__username']

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ['id', 'buyer', 'produce', 'quantity', 'total_price', 'status', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['buyer__username', 'produce__name']

@admin.register(MarketData)
class MarketDataAdmin(admin.ModelAdmin):
    list_display = ['produce_name', 'county', 'average_price', 'market_demand', 'date_recorded']
    list_filter = ['market_demand', 'county', 'date_recorded']
    search_fields = ['produce_name', 'county']

@admin.register(WeatherData)
class WeatherDataAdmin(admin.ModelAdmin):
    list_display = ['county', 'temperature', 'humidity', 'rainfall', 'date_recorded']
    list_filter = ['county', 'date_recorded']
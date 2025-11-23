# serializers.py
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import UserProfile, Produce, Order, MarketData

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']

class UserProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = UserProfile
        fields = '__all__'

class ProduceSerializer(serializers.ModelSerializer):
    farmer_name = serializers.CharField(source='farmer.get_full_name', read_only=True)
    farmer_location = serializers.CharField(source='farmer.userprofile.location', read_only=True)
    
    class Meta:
        model = Produce
        fields = '__all__'

class OrderSerializer(serializers.ModelSerializer):
    buyer_name = serializers.CharField(source='buyer.get_full_name', read_only=True)
    produce_name = serializers.CharField(source='produce.name', read_only=True)
    farmer_name = serializers.CharField(source='produce.farmer.get_full_name', read_only=True)
    
    class Meta:
        model = Order
        fields = '__all__'

class MarketDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = MarketData
        fields = '__all__'
# views.py
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib import messages  # Add this import for Django messages
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
import json
from django.utils import timezone
from datetime import datetime, timedelta

from .models import UserProfile, Produce, Order, MarketData, WeatherData
from .serializers import UserProfileSerializer, ProduceSerializer, OrderSerializer, MarketDataSerializer
from .ai_services import AIService
from .blockchain_services import BlockchainService
from .gis_services import GISService

# HTML Template Views
@api_view(['GET'])
@permission_classes([AllowAny])
def landing_page(request):
    """Landing page view"""
    return render(request, 'landing.html')

@api_view(['GET'])
@permission_classes([AllowAny])
def register_page(request):
    """Registration page view"""
    return render(request, 'register.html')

@api_view(['GET'])
@permission_classes([AllowAny])
def login_page(request):
    """Login page view"""
    return render(request, 'login.html')

@api_view(['GET'])
@login_required
def produce_list_page(request):
    """Produce listing page view"""
    produces = Produce.objects.filter(available=True)
    
    # Get filter parameters
    produce_type = request.GET.get('type')
    location = request.GET.get('location')
    
    if produce_type:
        produces = produces.filter(produce_type=produce_type)
    if location:
        produces = produces.filter(farmer__userprofile__location__icontains=location)
    
    return render(request, 'produce_list.html', {
        'produces': produces.order_by('-created_at'),
        'filter_type': produce_type,
        'filter_location': location
    })

@api_view(['GET'])
@login_required
def farmer_dashboard_page(request):
    """Farmer dashboard page view"""
    if request.user.userprofile.user_type != 'farmer':
        return redirect('produce-list-page')
    
    produces = Produce.objects.filter(farmer=request.user)
    orders = Order.objects.filter(produce__farmer=request.user)
    
    dashboard_data = {
        'total_products': produces.count(),
        'active_products': produces.filter(available=True).count(),
        'total_orders': orders.count(),
        'pending_orders': orders.filter(status='pending').count(),
        'total_revenue': sum([order.total_price for order in orders.filter(status='delivered')]),
        'recent_products': produces.order_by('-created_at')[:5],
        'recent_orders': orders.order_by('-created_at')[:5],
    }
    
    return render(request, 'farmer_dashboard.html', {'dashboard_data': dashboard_data})

@api_view(['GET'])
@login_required
def create_order_page(request, produce_id):
    """Order creation page view"""
    produce = get_object_or_404(Produce, id=produce_id, available=True)
    return render(request, 'create_order.html', {'produce': produce})

@api_view(['GET'])
@login_required
def market_analytics_page(request):
    """Market analytics page view"""
    produce_type = request.GET.get('type')
    county = request.GET.get('county')
    
    market_data = MarketData.objects.all()
    
    if produce_type:
        market_data = market_data.filter(produce_name__icontains=produce_type)
    if county:
        market_data = market_data.filter(county=county)
    
    # Calculate analytics
    if market_data.exists():
        avg_price = sum([d.average_price for d in market_data]) / len(market_data)
        high_demand_areas = market_data.filter(market_demand='high').count()
        total_areas = market_data.count()
        demand_ratio = (high_demand_areas / total_areas) * 100 if total_areas > 0 else 0
    else:
        avg_price = 0
        demand_ratio = 0
    
    analytics = {
        'average_market_price': round(avg_price, 2),
        'high_demand_percentage': round(demand_ratio, 2),
        'total_markets_analyzed': market_data.count(),
        'market_data': market_data.order_by('-date_recorded')[:10],
        'price_trend': 'stable',
    }
    
    return render(request, 'market_analytics.html', {'analytics': analytics})

@api_view(['GET'])
@login_required
def farms_map_page(request):
    """Farms map page view"""
    farmers = UserProfile.objects.filter(
        user_type='farmer',
        latitude__isnull=False,
        longitude__isnull=False
    )
    
    farms_data = []
    for farmer in farmers:
        produce_count = Produce.objects.filter(farmer=farmer.user, available=True).count()
        farms_data.append({
            'name': farmer.user.get_full_name() or farmer.user.username,
            'latitude': farmer.latitude,
            'longitude': farmer.longitude,
            'produce_count': produce_count,
            'location': farmer.location
        })
    
    map_html = GISService.create_farm_map(farms_data)
    
    return render(request, 'farms_map.html', {
        'map_html': map_html,
        'total_farms': len(farms_data),
        'farms_data': farms_data
    })

@api_view(['GET'])
@login_required
def add_produce_page(request):
    """Add produce page view"""
    if request.user.userprofile.user_type != 'farmer':
        return redirect('produce-list-page')
    return render(request, 'add_produce.html')

# API Views
@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    """API endpoint for user registration"""
    data = request.data
    
    try:
        # Create user
        user = User.objects.create_user(
            username=data['username'],
            email=data['email'],
            password=data['password'],
            first_name=data.get('first_name', ''),
            last_name=data.get('last_name', '')
        )
        
        # Create profile
        profile = UserProfile.objects.create(
            user=user,
            user_type=data['user_type'],
            phone_number=data.get('phone_number', ''),
            location=data.get('location', ''),
            latitude=data.get('latitude'),
            longitude=data.get('longitude')
        )
        
        # Auto-login after registration
        login(request, user)
        
        # Add success message for registration
        messages.success(request, f'Welcome to the platform, {user.get_full_name() or user.username}! Your account has been created successfully.')
        
        return Response({
            'message': 'User registered successfully',
            'success_message': f'Welcome to the platform, {user.get_full_name() or user.username}! Your account has been created successfully.',
            'user_id': user.id,
            'user_type': profile.user_type,
            'redirect': '/api/produce/'
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    """API endpoint for user login"""
    data = request.data
    
    try:
        user = authenticate(
            username=data['username'],
            password=data['password']
        )
        
        if user is not None:
            login(request, user)
            
            # Get user profile for personalized message
            profile = user.userprofile
            full_name = user.get_full_name() or user.username
            
            # Create personalized welcome message based on user type
            user_type_display = dict(UserProfile.USER_TYPES)[profile.user_type]
            welcome_message = f'Welcome back, {full_name}! You are logged in as a {user_type_display}.'
            
            # Add Django message for template rendering
            messages.success(request, welcome_message)
            
            # Determine redirect URL based on user type
            if profile.user_type == 'farmer':
                redirect_url = '/api/farmer/dashboard/'
            elif profile.user_type == 'buyer':
                redirect_url = '/api/produce/'
            elif profile.user_type == 'logistics':
                redirect_url = '/api/orders/'  # Assuming you have an orders view for logistics
            else:
                redirect_url = '/api/produce/'
            
            return Response({
                'message': 'Login successful',
                'success_message': welcome_message,
                'user_id': user.id,
                'user_type': profile.user_type,
                'user_name': full_name,
                'last_login': user.last_login.isoformat() if user.last_login else None,
                'redirect': redirect_url
            })
        else:
            return Response({
                'error': 'Invalid credentials. Please check your username and password.'
            }, status=status.HTTP_401_UNAUTHORIZED)
            
    except Exception as e:
        return Response({
            'error': f'Login failed: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@login_required
def logout_user(request):
    """API endpoint for user logout"""
    user_name = request.user.get_full_name() or request.user.username
    logout(request)
    
    # Add logout message
    messages.info(request, f'Goodbye {user_name}! You have been successfully logged out.')
    
    return Response({
        'message': 'Logout successful',
        'success_message': f'Goodbye {user_name}! You have been successfully logged out.',
        'redirect': '/api/'
    })

@api_view(['POST'])
@login_required
def create_order_api(request):
    """API endpoint for order creation"""
    if request.user.userprofile.user_type != 'buyer':
        return Response({'error': 'Only buyers can create orders'}, status=status.HTTP_403_FORBIDDEN)
    
    data = request.data
    
    try:
        produce = get_object_or_404(Produce, id=data['produce_id'])
        
        if float(data['quantity']) > float(produce.quantity):
            return Response({'error': 'Insufficient quantity available'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Create order
        order = Order.objects.create(
            buyer=request.user,
            produce=produce,
            quantity=data['quantity'],
            delivery_address=data['delivery_address'],
            delivery_latitude=data.get('delivery_latitude'),
            delivery_longitude=data.get('delivery_longitude')
        )
        
        # Create blockchain smart contract
        tx_hash = BlockchainService.create_smart_contract(order)
        order.blockchain_tx_hash = tx_hash
        order.save()
        
        # Update produce quantity
        produce.quantity -= float(data['quantity'])
        if produce.quantity == 0:
            produce.available = False
        produce.save()
        
        # Add success message
        success_msg = f'Order created successfully for {produce.name}! Order ID: {str(order.id)[:8]}...'
        messages.success(request, success_msg)
        
        return Response({
            'message': 'Order created successfully',
            'success_message': success_msg,
            'order_id': str(order.id),
            'blockchain_hash': tx_hash,
            'redirect': f'/api/orders/{order.id}/'
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@login_required
def add_produce_api(request):
    """API endpoint for adding produce"""
    if request.user.userprofile.user_type != 'farmer':
        return Response({'error': 'Only farmers can add produce'}, status=status.HTTP_403_FORBIDDEN)
    
    data = request.data
    
    try:
        produce = Produce.objects.create(
            farmer=request.user,
            name=data['name'],
            produce_type=data['produce_type'],
            quantity=data['quantity'],
            unit=data['unit'],
            price_per_unit=data['price_per_unit'],
            quality_grade=data['quality_grade'],
            harvest_date=data['harvest_date'],
            expiry_date=data['expiry_date'],
            description=data.get('description', ''),
        )
        
        # AI price prediction
        predicted_price = AIService.predict_price(
            produce.name,
            request.user.userprofile.location,
            produce.price_per_unit
        )
        
        produce.ai_predicted_price = predicted_price
        produce.save()
        
        # Add success message
        success_msg = f'Your {produce.name} has been added successfully to the marketplace!'
        messages.success(request, success_msg)
        
        return Response({
            'message': 'Produce added successfully',
            'success_message': success_msg,
            'produce_id': produce.id,
            'predicted_price': predicted_price,
            'redirect': '/api/farmer/dashboard/'
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

# Keep your existing API views
@api_view(['GET'])
def farmer_dashboard(request):
    # ... your existing implementation
    pass

@api_view(['POST'])
def create_order(request):
    # ... your existing implementation
    pass

@api_view(['POST'])
def update_order_status(request, order_id):
    # ... your existing implementation
    pass

@api_view(['GET'])
def market_analytics(request):
    # ... your existing implementation
    pass

@api_view(['GET'])
def farms_map(request):
    # ... your existing implementation
    pass

@api_view(['GET'])
def delivery_optimization(request):
    # ... your existing implementation
    pass
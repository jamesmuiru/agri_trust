# ai_services.py
import random
import numpy as np
from datetime import datetime, timedelta
from .models import MarketData, WeatherData, Produce

class AIService:
    @staticmethod
    def predict_price(produce_name, county, base_price):
        """
        Simplified AI price prediction based on market trends and seasonality
        """
        try:
            # Get recent market data
            recent_data = MarketData.objects.filter(
                produce_name__icontains=produce_name,
                county=county,
                date_recorded__gte=datetime.now().date() - timedelta(days=30)
            )
            
            if recent_data.exists():
                avg_market_price = sum([d.average_price for d in recent_data]) / len(recent_data)
                market_factor = float(avg_market_price) / float(base_price) if base_price > 0 else 1.0
            else:
                market_factor = 1.0
            
            # Seasonal adjustment (simplified)
            month = datetime.now().month
            seasonal_factors = {
                1: 1.1, 2: 1.05, 3: 0.95, 4: 0.9, 5: 0.85, 6: 0.9,
                7: 0.95, 8: 1.0, 9: 1.05, 10: 1.1, 11: 1.15, 12: 1.2
            }
            seasonal_factor = seasonal_factors.get(month, 1.0)
            
            # Weather impact (simplified)
            try:
                recent_weather = WeatherData.objects.filter(
                    county=county,
                    date_recorded__gte=datetime.now().date() - timedelta(days=7)
                ).latest('date_recorded')
                
                weather_factor = 1.0
                if float(recent_weather.rainfall) > 50:  # Heavy rain
                    weather_factor = 1.1
                elif float(recent_weather.rainfall) < 5:  # Drought
                    weather_factor = 1.15
                    
            except WeatherData.DoesNotExist:
                weather_factor = 1.0
            
            # Calculate predicted price
            predicted_price = float(base_price) * market_factor * seasonal_factor * weather_factor
            
            # Add some randomness for realism
            variance = random.uniform(0.9, 1.1)
            predicted_price *= variance
            
            return round(predicted_price, 2)
            
        except Exception as e:
            print(f"Price prediction error: {e}")
            return float(base_price) * random.uniform(0.95, 1.05)
    
    @staticmethod
    def optimize_delivery_route(orders):
        """
        Simplified route optimization using nearest neighbor algorithm
        """
        if not orders:
            return []
        
        # Extract coordinates
        locations = []
        for order in orders:
            if order.delivery_latitude and order.delivery_longitude:
                locations.append({
                    'order_id': order.id,
                    'lat': float(order.delivery_latitude),
                    'lng': float(order.delivery_longitude)
                })
        
        if len(locations) <= 1:
            return [loc['order_id'] for loc in locations]
        
        # Simple nearest neighbor algorithm
        route = [locations[0]]
        remaining = locations[1:]
        
        while remaining:
            current = route[-1]
            nearest = min(remaining, key=lambda loc: 
                         ((loc['lat'] - current['lat'])**2 + (loc['lng'] - current['lng'])**2)**0.5)
            route.append(nearest)
            remaining.remove(nearest)
        
        return [loc['order_id'] for loc in route]
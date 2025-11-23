# gis_services.py
import folium
from geopy.distance import geodesic
from django.conf import settings
import os

class GISService:
    @staticmethod
    def create_farm_map(farms_data):
        """
        Create a map showing farm locations
        """
        if not farms_data:
            # Default to Kenya center
            center_lat, center_lng = -0.0236, 37.9062
        else:
            # Calculate center from farms
            lats = [float(farm['latitude']) for farm in farms_data if farm['latitude']]
            lngs = [float(farm['longitude']) for farm in farms_data if farm['longitude']]
            center_lat = sum(lats) / len(lats) if lats else -0.0236
            center_lng = sum(lngs) / len(lngs) if lngs else 37.9062
        
        # Create map
        m = folium.Map(location=[center_lat, center_lng], zoom_start=7)
        
        # Add farm markers
        for farm in farms_data:
            if farm['latitude'] and farm['longitude']:
                folium.Marker(
                    [float(farm['latitude']), float(farm['longitude'])],
                    popup=f"{farm['name']} - {farm['produce_count']} products",
                    icon=folium.Icon(color='green', icon='leaf')
                ).add_to(m)
        
        return m._repr_html_()
    
    @staticmethod
    def calculate_delivery_distance(origin_lat, origin_lng, dest_lat, dest_lng):
        """
        Calculate distance between two points
        """
        try:
            origin = (float(origin_lat), float(origin_lng))
            destination = (float(dest_lat), float(dest_lng))
            distance = geodesic(origin, destination).kilometers
            return round(distance, 2)
        except:
            return 0

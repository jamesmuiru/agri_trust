from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from agritrust_app.models import UserProfile, Produce, Order, MarketData, WeatherData
from django.utils import timezone
from datetime import timedelta, date
import random


class Command(BaseCommand):
    help = "Populate database with sample data for AgriTrust"

    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.SUCCESS("Starting sample data population..."))

        # --- Create sample users ---
        users_data = [
            {"username": "farmer1", "password": "password123", "user_type": "farmer"},
            {"username": "farmer2", "password": "password123", "user_type": "farmer"},
            {"username": "buyer1", "password": "password123", "user_type": "buyer"},
            {"username": "buyer2", "password": "password123", "user_type": "buyer"},
            {"username": "logistics1", "password": "password123", "user_type": "logistics"},
        ]

        created_users = {}
        for data in users_data:
            user, created = User.objects.get_or_create(username=data["username"])
            if created:
                user.set_password(data["password"])
                user.save()
            profile, _ = UserProfile.objects.get_or_create(user=user, user_type=data["user_type"])
            created_users[data["username"]] = user

        # --- Create sample produce ---
        produce_samples = [
            ("Tomatoes", "vegetables"),
            ("Mangoes", "fruits"),
            ("Maize", "grains"),
            ("Beans", "legumes"),
            ("Potatoes", "tubers"),
        ]

        farmers = [created_users["farmer1"], created_users["farmer2"]]
        for farmer in farmers:
            for name, produce_type in produce_samples:
                harvest_date = date.today() - timedelta(days=random.randint(0, 5))
                expiry_date = harvest_date + timedelta(days=random.randint(5, 15))

                Produce.objects.update_or_create(
                    farmer=farmer,
                    name=name,
                    harvest_date=harvest_date,  # 🔑 part of uniqueness constraint
                    defaults={
                        "produce_type": produce_type,
                        "quantity": random.randint(50, 200),
                        "unit": "kg",
                        "price_per_unit": random.uniform(10, 50),
                        "quality_grade": random.choice(["A", "B", "C"]),
                        "expiry_date": expiry_date,
                        "description": f"{name} harvested in {farmer.username}'s farm",
                        "available": True,
                    },
                )

        # --- Create sample orders ---
        buyer = created_users["buyer1"]
        produce_item = Produce.objects.first()
        if produce_item:
            Order.objects.update_or_create(
                buyer=buyer,
                produce=produce_item,
                quantity=10,
                defaults={
                    "total_price": 10 * produce_item.price_per_unit,
                    "status": "pending",
                    "delivery_address": "Nairobi, Kenya",
                },
            )

        # --- Create sample market data ---
        counties = ["Nairobi", "Kisumu", "Mombasa", "Nakuru"]
        for name, _ in produce_samples:
            for county in counties:
                MarketData.objects.update_or_create(
                    produce_name=name,
                    county=county,
                    date_recorded=date.today(),  # 🔑 part of uniqueness constraint
                    defaults={
                        "average_price": random.uniform(20, 100),
                        "market_demand": random.choice(["low", "medium", "high"]),
                    },
                )

        # --- Create sample weather data ---
        for county in counties:
            WeatherData.objects.update_or_create(
                county=county,
                date_recorded=date.today(),  # 🔑 part of uniqueness constraint
                defaults={
                    "temperature": random.uniform(18, 30),
                    "humidity": random.uniform(40, 80),
                    "rainfall": random.uniform(0, 50),
                },
            )

        self.stdout.write(self.style.SUCCESS("✅ Sample data population completed successfully!"))

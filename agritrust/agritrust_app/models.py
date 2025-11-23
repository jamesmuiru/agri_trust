# models.py
from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
import uuid

class UserProfile(models.Model):
    USER_TYPES = [
        ('farmer', 'Farmer'),
        ('buyer', 'Buyer'),
        ('logistics', 'Logistics Partner'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    user_type = models.CharField(max_length=10, choices=USER_TYPES)
    phone_number = models.CharField(max_length=15, blank=True)
    location = models.CharField(max_length=100, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user.username} - {self.user_type}"

class Produce(models.Model):
    PRODUCE_TYPES = [
        ('vegetables', 'Vegetables'),
        ('fruits', 'Fruits'),
        ('grains', 'Grains'),
        ('legumes', 'Legumes'),
        ('tubers', 'Tubers'),
    ]
    
    QUALITY_GRADES = [
        ('A', 'Grade A - Premium'),
        ('B', 'Grade B - Standard'),
        ('C', 'Grade C - Basic'),
    ]
    
    farmer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='produce_listings',
        limit_choices_to={'userprofile__user_type': 'farmer'}
    )
    name = models.CharField(max_length=100)
    produce_type = models.CharField(max_length=20, choices=PRODUCE_TYPES)
    quantity = models.DecimalField(
        max_digits=10, decimal_places=2,
        validators=[MinValueValidator(0.1)]
    )
    unit = models.CharField(max_length=20, default='kg')
    price_per_unit = models.DecimalField(
        max_digits=10, decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )
    quality_grade = models.CharField(max_length=1, choices=QUALITY_GRADES)
    harvest_date = models.DateField()
    expiry_date = models.DateField()
    description = models.TextField(blank=True)
    image = models.ImageField(upload_to='produce/', blank=True, null=True)
    available = models.BooleanField(default=True)
    ai_predicted_price = models.DecimalField(
        max_digits=10, decimal_places=2,
        null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['farmer', 'name', 'harvest_date']
        ordering = ['-created_at']  # optional: newest first
    
    def __str__(self):
        return f"{self.name} ({self.harvest_date}) - {self.farmer.username}"


class Order(models.Model):
    ORDER_STATUS = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('in_transit', 'In Transit'),
        ('delivered', 'Delivered'),
        ('cancelled', 'Cancelled'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    buyer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='orders_as_buyer', 
                             limit_choices_to={'userprofile__user_type': 'buyer'})
    produce = models.ForeignKey(Produce, on_delete=models.CASCADE)
    quantity = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0.1)])
    total_price = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=15, choices=ORDER_STATUS, default='pending')
    delivery_address = models.TextField()
    delivery_latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    delivery_longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    logistics_partner = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True,
                                        related_name='orders_as_logistics',
                                        limit_choices_to={'userprofile__user_type': 'logistics'})
    blockchain_tx_hash = models.CharField(max_length=66, blank=True)  # Simulated blockchain hash
    escrow_released = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        if not self.total_price:
            self.total_price = self.quantity * self.produce.price_per_unit
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"Order {self.id} - {self.buyer.username}"

class MarketData(models.Model):
    produce_name = models.CharField(max_length=100)
    county = models.CharField(max_length=50)
    average_price = models.DecimalField(max_digits=10, decimal_places=2)
    market_demand = models.CharField(max_length=20, choices=[
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
    ])
    date_recorded = models.DateField(auto_now_add=True)
    
    class Meta:
        unique_together = ['produce_name', 'county', 'date_recorded']
    
    def __str__(self):
        return f"{self.produce_name} - {self.county} - {self.date_recorded}"

class WeatherData(models.Model):
    county = models.CharField(max_length=50)
    temperature = models.DecimalField(max_digits=5, decimal_places=2)
    humidity = models.DecimalField(max_digits=5, decimal_places=2)
    rainfall = models.DecimalField(max_digits=8, decimal_places=2)
    date_recorded = models.DateField(auto_now_add=True)
    
    class Meta:
        unique_together = ['county', 'date_recorded']
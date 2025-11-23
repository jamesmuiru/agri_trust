# agritrust/urls.py
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('agritrust_app.urls')),  # 👈 include app urls under /api/
]

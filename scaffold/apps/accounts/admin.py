from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, FarmerProfile, VeterinarianProfile, TechnicianProfile

admin.site.register(User, UserAdmin)
admin.site.register(FarmerProfile)
admin.site.register(VeterinarianProfile)
admin.site.register(TechnicianProfile)

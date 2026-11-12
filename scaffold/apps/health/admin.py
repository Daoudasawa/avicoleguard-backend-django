from django.contrib import admin
from .models import AlertRule

@admin.register(AlertRule)
class AlertRuleAdmin(admin.ModelAdmin):
    list_display = ('code', 'severity', 'threshold_value', 'trend_window_days', 'is_active')
    list_filter = ('is_active', 'severity')
    search_fields = ('code', 'description')

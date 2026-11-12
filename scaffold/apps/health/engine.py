from django.utils import timezone
from datetime import timedelta
from django.db.models import Sum
from apps.flocks.models import Flock
from apps.mortality.models import Mortality
from apps.alerts.models import Alert
from .models import AlertRule, HealthAnalysis, RiskLevel

def calculate_mortality_rate(flock, window_days):
    start_date = timezone.now().date() - timedelta(days=window_days)
    mortalities = Mortality.active.filter(flock=flock, date__gte=start_date)
    dead_count = mortalities.aggregate(Sum("dead_count"))["dead_count__sum"] or 0
    
    if flock.initial_count == 0:
        return 0
    return (dead_count / flock.initial_count) * 100

def run_health_analysis(flock_id):
    try:
        flock = Flock.objects.get(id=flock_id)
    except Flock.DoesNotExist:
        return None

    if flock.status == Flock.Status.CLOSED:
        return None
        
    rules = AlertRule.objects.filter(is_active=True)
    if not rules.exists():
        return None
        
    max_risk_level = RiskLevel.INFORMATION
    alerts_to_create = []
    
    analysis = HealthAnalysis.objects.create(
        flock=flock,
        risk_level=RiskLevel.INFORMATION,
        score=0.0,
        confidence=1.0, # Baseline
        explanation="Analyse automatique exécutée."
    )
    
    for rule in rules:
        # Simplistic rule engine implementation
        triggered = False
        value = 0
        
        if rule.code.startswith("MORTALITY_"):
            value = calculate_mortality_rate(flock, rule.trend_window_days)
            if value >= rule.threshold_value:
                triggered = True
                
        if triggered:
            # RM12 check anti-repetition: don't create if same rule triggered in last 24h
            cutoff = timezone.now() - timedelta(hours=24)
            recent_alert = Alert.objects.filter(
                flock=flock, rule_code=rule.code, created_at__gte=cutoff
            ).exists()
            
            if not recent_alert:
                alerts_to_create.append(
                    Alert(
                        flock=flock,
                        health_analysis=analysis,
                        rule_code=rule.code,
                        title=f"Alerte: {rule.description} (Valeur: {value:.2f})",
                        level=rule.severity
                    )
                )
                # Keep track of max severity
                severity_order = [RiskLevel.INFORMATION, RiskLevel.ATTENTION, RiskLevel.PREOCCUPANT, RiskLevel.CRITIQUE]
                if severity_order.index(rule.severity) > severity_order.index(max_risk_level):
                    max_risk_level = rule.severity
                    
    if alerts_to_create:
        Alert.objects.bulk_create(alerts_to_create)
        analysis.risk_level = max_risk_level
        analysis.save(update_fields=["risk_level"])
        
    return analysis

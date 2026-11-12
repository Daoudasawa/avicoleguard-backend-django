from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ContentCategoryViewSet, EducationalContentViewSet

router = DefaultRouter()
router.register(r"education/categories", ContentCategoryViewSet, basename="education-category")
router.register(r"education/articles", EducationalContentViewSet, basename="education-article")

app_name = "education"

urlpatterns = [
    path("", include(router.urls)),
]

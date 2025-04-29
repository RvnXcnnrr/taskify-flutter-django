# tasks/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TaskViewSet

router = DefaultRouter()
router.register(r'', TaskViewSet, basename='task')  # use '' to mount at root of app

urlpatterns = [
    path('', include(router.urls)),
]

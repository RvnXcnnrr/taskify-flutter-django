from django.contrib import admin
from .models import Task

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'is_completed', 'due_date', 'category')
    list_filter = ('is_completed', 'category')
    search_fields = ('title', 'description')

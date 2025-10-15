from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone



class User(AbstractUser):
    is_premium = models.BooleanField(default=False)
    points = models.IntegerField(default=0)
    reading_streak = models.IntegerField(default=0)
    last_read_date = models.DateField(null=True, blank=True)



class Comment(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=500)
    text = models.TextField()
    submitted_at = models.DateTimeField(auto_now_add=True)


class Bookmark(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=500)
    url = models.URLField(default='https://example.com')  # ✅ Add default URL
    language = models.CharField(max_length=10, default='en')
    created_at = models.DateTimeField(default=timezone.now)


class ReadingLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=500)
    category = models.CharField(max_length=100)
    language = models.CharField(max_length=10, default='en')
    timestamp = models.DateTimeField(default=timezone.now)  # ✅ temporary fix

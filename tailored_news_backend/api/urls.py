from django.urls import path
from .views import SummaryView, RecommendationView, CommentView
from .views import ReadingLogView, AnalyticsView, RegisterView
from .views import LoginView, SentimentAnalysisView
from .views import BookmarkView, PremiumSummaryUnlockView
from .views import LogReadingView, UserProfileView, UpgradeToPremiumView

urlpatterns = [
    path('summary/', SummaryView.as_view()),
    path('recommend/', RecommendationView.as_view()),
    path('comment/', CommentView.as_view()),
    path('readinglog/', ReadingLogView.as_view()),
    path('analytics/', AnalyticsView.as_view()),
    path('register/', RegisterView.as_view()),
    path('login/', LoginView.as_view()),
    path('sentiment/', SentimentAnalysisView.as_view()),
    path('bookmark/', BookmarkView.as_view()),
    path('summary/unlock/', PremiumSummaryUnlockView.as_view()),
    path('reading/log/', LogReadingView.as_view()),
    path('user/profile/', UserProfileView.as_view()),
    path('user/upgrade/', UpgradeToPremiumView.as_view()),
]

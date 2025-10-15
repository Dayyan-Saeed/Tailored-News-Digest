from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from django.db.models import Count
from .models import Comment, Bookmark, ReadingLog, User
from .serializers import CommentSerializer, BookmarkSerializer, UserSerializer
from .serializers import ReadingLogSerializer, RegisterSerializer
from transformers import T5Tokenizer, T5ForConditionalGeneration
from transformers import MBartForConditionalGeneration, MBart50Tokenizer
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM, pipeline
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from django.utils import timezone



class RegisterView(APIView):
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "User registered successfully."},
                            status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    def post(self, request):
        username = request.data.get("username")
        password = request.data.get("password")
        user = authenticate(username=username, password=password)
        if user is not None:
            refresh = RefreshToken.for_user(user)
            return Response({
                "refresh": str(refresh),
                "access": str(refresh.access_token),
                "username": user.username,
                "is_premium": user.is_premium,
                "points": user.points
            })
        return Response({"error": "Invalid credentials"},
                        status=status.HTTP_401_UNAUTHORIZED)


class SummaryView(APIView):
    def post(self, request):
        content = request.data.get("content")
        language = request.data.get("language", "en")
        if not content:
            return Response({"error": "No content provided"}, status=400)
        try:
            if language == "ur":
                tokenizer = AutoTokenizer.from_pretrained(
                    "eslamxm/mt5-base-finetuned-urdu")
                model = AutoModelForSeq2SeqLM.from_pretrained(
                    "eslamxm/mt5-base-finetuned-urdu")
            else:
                tokenizer = T5Tokenizer.from_pretrained("t5-small")
                model = T5ForConditionalGeneration.from_pretrained("t5-small")
            inputs = tokenizer(content, return_tensors="pt",
                               max_length=512, truncation=True)
            summary_ids = model.generate(inputs["input_ids"],
                                         max_length=150, min_length=30,
                                         num_beams=4)
            summary = tokenizer.decode(
                summary_ids[0], skip_special_tokens=True)
            return Response({"summary": summary})
        except Exception as e:
            return Response({"error": str(e)}, status=500)


class SentimentAnalysisView(APIView):
    def post(self, request):
        content = request.data.get("content")
        language = request.data.get("language", "en")
        if not content:
            return Response({"error": "Missing content"}, status=400)
        if language == "ur":
            model_name = "mahwizzzz/UrduClassification"
            tokenizer = pipeline("sentiment-analysis", model=model_name)
            result = tokenizer(content)[0]
        else:
            sentiment_pipeline = pipeline("sentiment-analysis")
            result = sentiment_pipeline(content)[0]
        return Response({"label": result['label'], "score": result['score']})


class RecommendationView(APIView):
    def post(self, request):
        current_article = request.data.get("current_article")
        all_articles = request.data.get("all_articles")
        if not current_article or not all_articles:
            return Response(
                {"error": "current_article and all_articles are required"},
                status=400)
        try:
            language = request.data.get("language", "en")
            tfidf = TfidfVectorizer(
                stop_words="english" if language == "en" else None)
            contents = [article["content"] for article in all_articles]
            tfidf_matrix = tfidf.fit_transform(contents)
            current_idx = 0
            cos_sim = cosine_similarity(
                tfidf_matrix[current_idx], tfidf_matrix).flatten()
            similar_indices = cos_sim.argsort()[1:4]
            recommendations = [all_articles[i] for i in similar_indices]
            return Response({"recommendations": recommendations})
        except Exception as e:
            return Response({"error": str(e)}, status=500)


class CommentView(APIView):
    def post(self, request):
        serializer = CommentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Comment recorded"}, status=201)
        return Response(serializer.errors, status=400)

class BookmarkView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        data = request.data.copy()
        data['user'] = request.user.id
        serializer = BookmarkSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Article bookmarked"}, status=201)
        return Response(serializer.errors, status=400)


class ReadingLogView(APIView):
    def post(self, request):
        serializer = ReadingLogSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Reading log saved"}, status=201)
        return Response(serializer.errors, status=400)


class AnalyticsView(APIView):
    def get(self, request):
        logs = ReadingLog.objects.all()
        data = {"english": {}, "urdu": {}}
        for log in logs:
            lang_key = "urdu" if log.language == "ur" else "english"
            data[lang_key]["total"] = data[lang_key].get("total", 0) + 1
            cat = log.category
            data[lang_key][cat] = data[lang_key].get(cat, 0) + 1
        return Response(data)


class PremiumSummaryUnlockView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        if user.is_premium:
            return Response({"access": "granted", "reason": "premium"},
                            status=status.HTTP_200_OK)
        if user.points > 0:
            user.points -= 1
            user.save()
            return Response({"access": "granted", "reason": "points_deducted"},
                            status=status.HTTP_200_OK)
        return Response({"access": "denied", "reason": "insufficient_points"},
                        status=status.HTTP_403_FORBIDDEN)


class LogReadingView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        data = {
            'user': user.id,
            'title': request.data.get('title'),
            'category': request.data.get('category'),
            'language': request.data.get('language', 'en')
        }
        serializer = ReadingLogSerializer(data=data)
        if serializer.is_valid():
            serializer.save()

            today = timezone.now().date()
            if user.last_read_date == today:
                pass  # already logged today
            elif user.last_read_date == today - timezone.timedelta(days=1):
                user.reading_streak += 1
                user.last_read_date = today
                user.save()
            else:
                user.reading_streak = 1
                user.last_read_date = today
                user.save()

            return Response({"message": "Reading logged."},
                            status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        serializer = UserSerializer(user)
        return Response(serializer.data)


class UpgradeToPremiumView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        if user.points >= 10:
            user.points -= 10
            user.is_premium = True
            user.save()
            return Response({"message": "User upgraded to premium."})
        else:
            return Response({"error": "Not enough points to upgrade."},
                            status=status.HTTP_400_BAD_REQUEST)

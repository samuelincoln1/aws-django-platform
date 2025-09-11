import json
from django.http import JsonResponse, HttpResponseNotAllowed
from django.shortcuts import render, get_object_or_404
from django.views.decorators.csrf import csrf_exempt
from django.db import transaction
from .models import Item

@csrf_exempt
def healthz(request):
    try:
        # Test connection with database
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        return JsonResponse({
            "status": "healthy",
            "database": "connected",
            "service": "django-app"
        })
    except Exception as e:
        return JsonResponse({
            "status": "unhealthy", 
            "error": str(e),
            "database": "disconnected"
        }, status=500)


def home(request):
    return render(request, "core/index.html")

@csrf_exempt
def items_list(request):
    if request.method == "GET":
        data = [i.as_dict() for i in Item.objects.order_by("-id")]
        return JsonResponse(data, safe=False)
    if request.method == "POST":
        try:
            payload = json.loads(request.body or "{}")
            name = payload.get("name")
            if not name:
                return JsonResponse({"error": "name é obrigatório"}, status=400)
            item = Item.objects.create(name=name)
            return JsonResponse(item.as_dict(), status=201)
        except json.JSONDecodeError:
            return JsonResponse({"error": "JSON inválido"}, status=400)
    return HttpResponseNotAllowed(["GET", "POST"])

@csrf_exempt
def item_detail(request, id):
    item = get_object_or_404(Item, id=id)
    if request.method == "GET":
        return JsonResponse(item.as_dict())
    if request.method in ["PUT", "PATCH"]:
        try:
            payload = json.loads(request.body or "{}")
            name = payload.get("name")
            if name:
                item.name = name
                item.save()
            return JsonResponse(item.as_dict())
        except json.JSONDecodeError:
            return JsonResponse({"error": "JSON inválido"}, status=400)
    if request.method == "DELETE":
        with transaction.atomic():
            item.delete()
            transaction.on_commit(lambda: print(f"Item {id} deletado e commitado!"))
        return JsonResponse({"deleted": True}, status=200)
    return HttpResponseNotAllowed(["GET", "PUT", "PATCH", "DELETE"])
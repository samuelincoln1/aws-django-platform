import json
import logging

from django.http import HttpResponse, JsonResponse
from django.shortcuts import get_object_or_404, render
from django.views.decorators.csrf import ensure_csrf_cookie
from django.views.decorators.http import require_http_methods

from .models import Item

logger = logging.getLogger(__name__)

NAME_MAX_LENGTH = Item._meta.get_field("name").max_length


def parse_name(request):
    """Returns (name, error_response) from a JSON body with a "name" field."""
    try:
        payload = json.loads(request.body or "{}")
    except json.JSONDecodeError:
        return None, JsonResponse({"error": "Invalid JSON"}, status=400)

    name = payload.get("name") if isinstance(payload, dict) else None
    if not isinstance(name, str) or not name.strip():
        return None, JsonResponse({"error": "name is required"}, status=400)

    name = name.strip()
    if len(name) > NAME_MAX_LENGTH:
        return None, JsonResponse(
            {"error": f"name must have at most {NAME_MAX_LENGTH} characters"}, status=400
        )
    return name, None


@ensure_csrf_cookie
def home(request):
    return render(request, "core/index.html")


@require_http_methods(["GET", "POST"])
def items_list(request):
    if request.method == "GET":
        return JsonResponse([item.as_dict() for item in Item.objects.order_by("-id")], safe=False)

    name, error = parse_name(request)
    if error:
        return error
    item = Item.objects.create(name=name)
    logger.info("Item %s created", item.pk)
    return JsonResponse(item.as_dict(), status=201)


@require_http_methods(["GET", "PUT", "PATCH", "DELETE"])
def item_detail(request, pk):
    item = get_object_or_404(Item, pk=pk)

    if request.method == "GET":
        return JsonResponse(item.as_dict())

    if request.method == "DELETE":
        item.delete()
        logger.info("Item %s deleted", pk)
        return HttpResponse(status=204)

    name, error = parse_name(request)
    if error:
        return error
    item.name = name
    item.save(update_fields=["name", "updated_at"])
    logger.info("Item %s updated", pk)
    return JsonResponse(item.as_dict())

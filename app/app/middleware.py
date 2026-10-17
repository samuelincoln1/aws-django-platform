from django.http import JsonResponse


class HealthCheckMiddleware:
    """Answers /healthz/ before the rest of the middleware stack runs.

    ALB and container health checks send the task's private IP (or localhost)
    as Host and use plain HTTP, so a normal request would fail ALLOWED_HOSTS
    validation or be redirected to HTTPS.

    Liveness only: checking the database here would make the ALB drain every
    task during an RDS failover, turning a short blip into a full outage.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.path == "/healthz/":
            return JsonResponse({"status": "healthy"})
        return self.get_response(request)

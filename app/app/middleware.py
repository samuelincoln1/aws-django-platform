from django.utils.deprecation import MiddlewareMixin
import re

class HealthCheckMiddleware(MiddlewareMixin):
    def process_request(self, request):
        if request.path == '/healthz/':
            request.META['HTTP_HOST'] = 'localhost'
        return None 
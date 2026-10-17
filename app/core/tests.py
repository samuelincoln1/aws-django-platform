import json

from django.test import Client, TestCase
from django.urls import reverse

from .models import Item


class HttpsClient(Client):
    """Sends requests as they arrive in AWS: HTTPS, as reported by the ALB."""

    def __init__(self, **kwargs):
        super().__init__(HTTP_X_FORWARDED_PROTO="https", **kwargs)


class HttpsTestCase(TestCase):
    client_class = HttpsClient


class HealthCheckTests(TestCase):
    def test_healthz_over_http_with_task_ip_as_host(self):
        # What the ALB sends: plain HTTP, private IP as Host
        response = Client().get("/healthz/", HTTP_HOST="10.0.3.25:8000")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "healthy"})

    def test_other_paths_still_validate_host(self):
        response = self.client.get("/", HTTP_HOST="evil.example.com", HTTP_X_FORWARDED_PROTO="https")
        self.assertEqual(response.status_code, 400)


class ItemsApiTests(HttpsTestCase):
    def post_json(self, url, data, method="post"):
        return getattr(self.client, method)(
            url, data=json.dumps(data), content_type="application/json"
        )

    def test_list_returns_newest_first(self):
        Item.objects.create(name="first")
        Item.objects.create(name="second")

        response = self.client.get(reverse("items_list"))

        self.assertEqual(response.status_code, 200)
        self.assertEqual([item["name"] for item in response.json()], ["second", "first"])

    def test_create(self):
        response = self.post_json(reverse("items_list"), {"name": "  new item  "})

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.json()["name"], "new item")
        self.assertTrue(Item.objects.filter(name="new item").exists())

    def test_create_validates_name(self):
        cases = [{}, {"name": ""}, {"name": "   "}, {"name": 42}, {"name": "x" * 201}]
        for payload in cases:
            with self.subTest(payload=payload):
                response = self.post_json(reverse("items_list"), payload)
                self.assertEqual(response.status_code, 400)
        self.assertEqual(Item.objects.count(), 0)

    def test_create_rejects_invalid_json(self):
        response = self.client.post(
            reverse("items_list"), data="not json", content_type="application/json"
        )
        self.assertEqual(response.status_code, 400)

    def test_update(self):
        item = Item.objects.create(name="old")

        response = self.post_json(reverse("item_detail", args=[item.pk]), {"name": "new"}, "patch")

        self.assertEqual(response.status_code, 200)
        item.refresh_from_db()
        self.assertEqual(item.name, "new")

    def test_delete(self):
        item = Item.objects.create(name="to delete")

        response = self.client.delete(reverse("item_detail", args=[item.pk]))

        self.assertEqual(response.status_code, 204)
        self.assertFalse(Item.objects.filter(pk=item.pk).exists())

    def test_missing_item_returns_404(self):
        response = self.client.get(reverse("item_detail", args=[999]))
        self.assertEqual(response.status_code, 404)

    def test_method_not_allowed(self):
        response = self.client.put(reverse("items_list"))
        self.assertEqual(response.status_code, 405)


class CsrfTests(TestCase):
    def setUp(self):
        self.client = HttpsClient(enforce_csrf_checks=True)

    def test_write_without_token_is_rejected(self):
        response = self.client.post(
            reverse("items_list"), data=json.dumps({"name": "x"}), content_type="application/json"
        )
        self.assertEqual(response.status_code, 403)

    def test_write_with_token_from_home_page(self):
        page = self.client.get(reverse("home")).wsgi_request
        token = self.client.cookies["csrftoken"].value
        # Browsers send Origin on fetch() POST; it must match the site's own origin
        origin = f"{page.scheme}://{page.get_host()}"

        response = self.client.post(
            reverse("items_list"),
            data=json.dumps({"name": "x"}),
            content_type="application/json",
            HTTP_X_CSRFTOKEN=token,
            HTTP_ORIGIN=origin,
        )
        self.assertEqual(response.status_code, 201)

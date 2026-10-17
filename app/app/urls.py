from django.contrib import admin
from django.urls import path

from core.views import home, item_detail, items_list

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", home, name="home"),
    path("api/items/", items_list, name="items_list"),
    path("api/items/<int:pk>/", item_detail, name="item_detail"),
]

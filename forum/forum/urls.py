from django.conf.urls import *
from django.conf.urls import url
from django.contrib import admin

from .views import *
urlpatterns = [
    url(r'^$', index, name='index'),
    url(r'^topic/new/$', create_topic, name='create_topic'),
    url(r'^topic/(?P<id>\d+)/$', topic, name='topic_id'),
    url(r'^topic/(?P<slug>[^/]+)/$', topic, name='topic_slug'),
    url(r'^forum/(?P<id>\d+)/$', forum, name='forum'),
]

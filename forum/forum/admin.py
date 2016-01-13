from adminsortable2.admin import SortableAdminMixin
from adminsortable2.admin import SortableInlineAdminMixin

from django.conf import settings
from django.contrib import admin
from django.utils.translation import ugettext_lazy as _

from .models import *

class ForumInline(SortableInlineAdminMixin, admin.TabularInline):  # or admin.StackedInline
    model = Forum
    fields = ['name','slug', 'position' ]
    extra = 1
class CategoryAdmin(SortableAdminMixin,  admin.ModelAdmin):
    list_display = ['name', 'position']

    inlines = (ForumInline,)


class ForumAdmin(admin.ModelAdmin):
    list_display = ['name', 'category',  'topic_count']
    raw_id_fields = ['moderators', 'last_post']


class TopicAdmin(admin.ModelAdmin):

    def subscribers2(self, obj):
        return ", ".join([user.username for user in obj.subscribers.all()])
    subscribers2.short_description = _("subscribers")

    list_display = ['name', 'forum', 'created',  'post_count', 'subscribers2']
    search_fields = ['name']
    raw_id_fields = ['user', 'subscribers', 'last_post']


class CommentAdmin(admin.ModelAdmin):
    list_display = ['topic', 'user', 'created', 'updated']
    search_fields = ['body']
    raw_id_fields = ['topic', 'user']


admin.site.register(Category, CategoryAdmin)
admin.site.register(Forum, ForumAdmin)
admin.site.register(Topic, TopicAdmin)
admin.site.register(Comment, CommentAdmin)
admin.site.register(User)

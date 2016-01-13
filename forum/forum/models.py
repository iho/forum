from django.contrib.auth.models import AbstractUser
from django.contrib.postgres.fields import ArrayField
from django.db import models
from django.utils import timezone
from django.utils.translation import ugettext_lazy as _

from django.core.urlresolvers import reverse

class User(AbstractUser):
    avatar = models.ImageField(upload_to='avatars',
                               blank=True,
                               null=True,
                               )


class Category(models.Model):
    name = models.CharField(_('Name'), max_length=80)
    position = models.IntegerField(_('Position'), blank=True, default=0)
    slug = models.CharField(_('Slug'), max_length=245, blank=True, null=True)

    class Meta:
        ordering = ['position']

    def __str__(self):
        return self.name


class Forum(models.Model):
    slug = models.CharField(_('Slug'), max_length=245, blank=True, null=True)
    category = models.ForeignKey(
        Category, related_name='forums', verbose_name=_('Category'))
    name = models.CharField(_('Name'), max_length=80)
    position = models.IntegerField(_('Position'), blank=True, default=0)
    description = models.TextField(_('Description'), blank=True, default='')
    moderators = models.ManyToManyField(
        User, blank=True, verbose_name=_('Moderators'))
    updated = models.DateTimeField(_('Updated'), auto_now=True)
    post_count = models.IntegerField(_('Post count'), blank=True, default=0)
    topic_count = models.IntegerField(_('Topic count'), blank=True, default=0)
    last_post = models.ForeignKey(
        'Comment', related_name='+', blank=True, null=True)

    def get_absolute_url(self):
        return reverse('forum:forum', kwargs={'id':str(self.id)})




    class Meta:
        ordering = ['position']
        # verbose_name = _('Forum')
        # verbose_name_plural = _('Forums')

    def __str__(self):
        return self.name


import markdown2
markdowner=markdown2.Markdown( extras=["fenced-code-blocks"] )
class MarkdownMixin(models.Model):
    body_md = models.TextField(_('Message'))
    body_html = models.TextField(_('HTML version'))
    def save(self):
        self.body_html = markdowner.convert( self.body_md ) 
        super().save()
    class Meta:
        abstract = True

class Topic(MarkdownMixin, models.Model):
    name = models.CharField(_('Name'), max_length=255)
    slug = models.CharField(_('Slug'), max_length=245, blank=True, null=True)
    forum = models.ForeignKey(
        Forum, related_name='topics', verbose_name=_('Forum'))
    created = models.DateTimeField(_('Created'), auto_now_add=True)
    updated = models.DateTimeField(_('Updated'), null=True, blank=True)
    deleted = models.DateTimeField(_('Deleted'), null=True, blank=True)
    user = models.ForeignKey(User, verbose_name=_('User'))
    views = models.IntegerField(_('Views count'), blank=True, default=0)
    sticky = models.BooleanField(_('Sticky'), blank=True, default=False)
    closed = models.BooleanField(_('Closed'), blank=True, default=False)
    subscribers = models.ManyToManyField(
        User, related_name='subscriptions', verbose_name=_('Subscribers'), blank=True)
    post_count = models.IntegerField(_('Post count'), blank=True, default=0)
    last_post = models.ForeignKey(
        'Comment', related_name='+', blank=True, null=True)
    user_ip = models.GenericIPAddressField(_('User IP'), blank=True, null=True)
    
    class Meta:
        ordering = ['-updated']
        get_latest_by = 'updated'

    def get_absolute_url(self):
        return reverse('forum:topic_id', kwargs={'id':str(self.id)})

    def __str__(self):
        return self.name


class Comment(MarkdownMixin, models.Model):
    slug = models.CharField(_('Slug'), max_length=245, blank=True, null=True)
    topic = models.ForeignKey(
        Topic, related_name='comments', verbose_name=_('Topic'))
    user = models.ForeignKey(
        User, related_name='comments', verbose_name=_('User'))
    created = models.DateTimeField(_('Created'), auto_now_add=True)
    updated = models.DateTimeField(_('Updated'), blank=True, null=True)
    deleted = models.DateTimeField(_('Deleted'), null=True, blank=True)
    # updated_by = models.ForeignKey(settings.AUTH_USER_MODEL, verbose_name=_('Updated by'), blank=True, null=True)
    user_ip = models.GenericIPAddressField(_('User IP'), blank=True, null=True)
    likes = ArrayField(models.IntegerField(),  blank=True)

    parent = models.ForeignKey(
        'self', related_name='childs', blank=True, null=True)
    thread_root = models.ForeignKey(
        'self', related_name='thread_childs', blank=True, null=True)

    class Meta:
        ordering = ['-created']
        get_latest_by = '-created'

    def __str__(self):
        return str(self.id)

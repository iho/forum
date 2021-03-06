from django.db import connection, transaction
from django.db.models import Q
from django.http import *
from django.shortcuts import get_object_or_404, render
from django.views.decorators.cache import never_cache

from .models import *

from django.core.urlresolvers import reverse

# cursor = connection.cursor()


# @never_cache


def comment_sort(comments, reverse=False):
    # reverse=True
    return sorted(comments,
                  key=lambda y: y.created,
                  reverse=reverse
                  )


def to_tree(items):
    items = comment_sort(items)
    first_column = [x for x in items if
                    x.parent_id is None]
    first_column = comment_sort(first_column, reverse=True)
    items_dict = {}
    for x in items:
        setattr(x, 'children', [])
        items_dict[x.id] = x
    for x in items:
        id = getattr(x, 'parent_id')
        if id:
            tmp = items_dict[id]
            tmp = getattr(tmp, 'children', [])
            tmp.append(x)
    return first_column
# created
# parent_id


class Counter:
    value = 0

    @property
    def incr(self):
        self.value += 1
        c = Counter()
        c.value = self.value
        return c

    @property
    def new(self):
        return Counter()

    @property
    def copy(self):
        c = Counter()
        c.value = self.value
        return c


def index(request):
    context = {}
    context['categories'] = Category.objects.order_by('position')
    #context['categories'] = Category.objects.order_by('position').select_related('forums')
    return render(request, "forum/index.html", context)

def forum(request, id):
    context = {}
    forum = get_object_or_404(Forum, id=id)
    context['forum'] = forum
    context['title'] = forum.name
    #context['categories'] = Category.objects.order_by('position').select_related('forums')
    return render(request, "forum/forum.html", context)


def topic(request, id=None, slug=None):
    context = {}
    query = Topic.objects.filter(deleted=None)
    if id:
        query = query.filter(id=id)
    else:
        query = query.filter(slug=slug)
    topic = query.first()
    if not topic:
        raise Http404("Topic not found")
    context['topic'] = topic
    context['title'] = topic.name
    context['counter'] = Counter()
    comments = topic.comments.all()
    context['comments'] = comments
    context['comments_tree'] = to_tree(comments)
    return render(request, "forum/topic.html", context)

from .forms import TopicForm 

from django.utils.translation import ugettext_lazy as _

from django.shortcuts import redirect
from django.contrib import messages
def create_topic(request):
    context = {}

    form = TopicForm()
    if request.method == 'POST':
        form = TopicForm(request.POST)
        if form.is_valid():
            topic = form.save(commit=False)
            topic.user = request.user 
            topic.save()
            messages.success(request, _('New topic created'))
            return redirect(topic)
    context['form'] = form
    context['title'] = _('New topic')

    return render(request, "forum/form.html", context)



from django import forms

from django.forms import ModelForm

from .models import *


class UserForm(ModelForm):

    class Meta:
        model = User
        fields = [
            'first_name',
            'last_name',
            'email',
            'avatar']


class TopicForm(ModelForm):

    class Meta:
        model = Topic
        fields = ['name', 'body_md']

class CommentForm(ModelForm):
    class Meta:
        model = Comment
        fields = ['body_md']


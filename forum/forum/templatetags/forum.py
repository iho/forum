from django import template
register = template.Library()

@register.filter
def multiple(value, arg):    
    return int(value) * int(arg)

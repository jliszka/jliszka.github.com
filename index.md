---
layout: page
title: A Gentleman and a Scala
tagline: Understanding math through code
---
{% include JB/setup %}

## Archive
<ul class="posts">
  {% for post in site.posts %}
    <li><a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>

<div class="post-content-truncate">
{% for post in site.posts limit:10 %}
  {% if post.content contains "<!-- more -->" %}
    <h2 class="title">{{ post.title }}</h2>
    {{ post.content | split:"<!-- more -->" | first % }}
    <a href="{{ post.url }}">Read more</a>
    <hr/>
  {% endif %}
{% endfor %}
</div>

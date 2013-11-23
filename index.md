---
layout: page
title: A Gentleman and a Scala
tagline: Understanding math through code
---
{% include JB/setup %}

My name is Jason Liszka, and I'm a software engineer at Foursquare in New York.
This blog chronicles my attempt to understand math better through code.
I've always been interested in abstract math, but computation has always been more intuitive to me.
Realizing abstract structures in code makes them more concrete and makes it easier for me to wrap my puny human brain around them.

I'm a big fan of Scala and Haskell so you'll see a lot of code in those languages.

You should [follow me on twitter](http://twitter.com/jliszka). I promise I won't spam your feed.

I also make no claims about being a gentleman, title of this blog notwithstanding.

## Archive
<ul class="posts">
  {% for post in site.posts %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>

## Recent Posts
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
---
layout: post
title: "An effective pattern for programming with Futures"
description: ""
category: 
tags: []
---
{% include JB/setup %}

Twitter's Future library is a beautiful abstraction for dealing with concurrency. However, there are a few
code patterns that seem innocuous but can cause real trouble in production systems.

First I will present my ideal pattern for composing Futures. Then I'll show you all the ways it can go wrong.

### The ideal pattern

By way of example, below is a method in a fictional web application that registers a user by calling the Foursquare API
to get user details, their friend graph and their recent check-ins.

{% highlight scala %}
def registerUser(token: String): Future[User] = {
  val api = FoursquareApi(token)

  val apiUserF: Future[ApiUser] = api.getSelfF()
  val apiCategoriesF: Future[Seq[ApiCategory]] = api.getCategoriesF()

  def apiFriendsF(apiUser: ApiUser): Future[Seq[ApiUser]] = {
    future.groupedCollect(apiUser.friendIDs, 5)(api.getUserF)
  }

  def apiCheckinsF(apiUser: ApiUser, categoryies: Seq[ApiCategory]): Future[Seq[ApiCheckin]] = {
    ...
  }

  def createDBUserF(
      user: ApiUser,
      friends: Seq[ApiUser],
      checkins: Seq[ApiCheckin]): Future[User] = future {
    db.insert(...)
  }

  for {
    apiUser <- apiUserF
    apiCategories <- apiCategoriesF
    (apiFriends, apiCheckins) <- future.join(
      apiFriendsF(apiUser)
      apiCheckinsF(apiUser, apiCategories))
    user <- createDBUserF(apiUser, apiFriends, apiCheckins)
  } yield user
}
{% endhighlight %}

Things to note here:

* Futures and methods that return Futures end in ```F```
* Nested methods take plain values and return Futures, for great ```flatMap```ing
* All the work is set up ahead of time via ```val```s and nested methods
* Everything is "glued" together with a ```for```-comprehension at the end
* Parallelism and dependencies are made explicit in the ```for```-comprehension

### Anti-pattern #1: Doing work in a yield or a map

You might think that wrapping the body of ```createDBUserF``` in a Future just to unwrap it in the ```for```-comprehension
is unnecessary. After all, the last part of the ```for```-comprehension desugars to

{% highlight scala %}
createDBUserF(apiUser, friends, checkins).map(user => user)
{% endhighlight %}

That identity ```map``` seems useless. So you might be tempted to write:

{% highlight scala %}
def createDBUser(
    user: ApiUser,
    friends: Seq[ApiUser],
    checkins: Seq[ApiCheckin]): User = {
  db.insert(...)
}

for {
  apiUser <- apiUserF
  apiCategories <- apiCategoriesF
  (apiFriends, apiCheckins) <- future.join(
    apiFriendsF(apiUser)
    apiCheckinsF(apiUser, apiCategories))
} yield createDBUser(apiUser, apiFriends, apiCheckins)
{% endhighlight %}

But this is bad! It desugars to

{% highlight scala %}
future.join(...).map{ case (apiFriends, apiCheckins) => createDBUser(apiUser, apiFriends, apiCheckins) }
{% endhighlight %}

You should never do blocking work in ```map``` on a Future. Code inside the map runs after the Future
thread completes, but it runs on the scheduler thread, preventing it from doing any more scheduling, which is bad.
Also there is only one such thread, so you're losing an opportunity for parallelism. It's also possible to
cause a deadlock this way.

So ALWAYS ```yield``` a plain value or a simple computation.

### Anti-pattern #2: Too much parallelism

The method ```apiFriendsF``` creates a future for each item in a list of user IDs and collects the results into a single 
Future. You might be tempted to write it like this:

{% highlight scala %}
def apiFriendsF(apiUser: ApiUser): Future[Seq[ApiUser]] = {
  Future.collect(apiUser.friendIDs.map(api.getUserF))
}
{% endhighlight %}

But this is too much parallelism! You'll flood the thread pool with a ton of simultaneous work. Some network or database
drivers don't even allow more than a certain number of concurrent connections, and you'll get a bunch of exceptions, and
you will not have a good day. A better way to do it is to limit how much you are doing in parallel.

{% highlight scala %}
def apiFriendsF(apiUser: ApiUser): Future[Seq[ApiUser]] = {
  future.groupedCollect(apiUser.friendIDs, 5)(api.getUserF)
}
{% endhighlight %}

The ```groupedCollect``` utility method is defined as follows:

{% highlight scala %}
def groupedCollect[A, B](xs: Seq[A], par: Int)(f: A => Future[B]): Future[Seq[B]] = {
  val bsF: Future[Seq[B]] = Future.value(Seq.empty[B])
  xs.grouped(par).foldLeft(bsF){ case (bsF, group) => {
    for {
      bs <- bsF
      xs <- Future.collect(group.map(f))
    } yield bs ++ xs
  }}
}
{% endhighlight %}

The ```par``` parameter lets you specify how much work you want done in parallel. For example, if you specify 5, it will
take 5 items from the list, do them all in parallel, and wait for them to complete before moving on to the next 5 items.

### Anti-pattern #3: Not enough parallelism

It might seem redundant to write

{% highlight scala %}
val apiUserF: Future[ApiUser] = api.getSelfF()
val apiCategoriesF: Future[Seq[ApiCategory]] = api.getCategoriesF()
{% endhighlight %}

and then do

{% highlight scala %}
for {
  apiUser <- apiUserF
  apiCategories <- apiCategoriesF
  ...
} yield ...
{% endhighlight %}

Why not just do the following?

{% highlight scala %}
for {
  apiUser <- api.getSelfF()
  apiCategories <- api.getCategoriesF()
  ...
} yield ...
{% endhighlight %}

Well, this would invoke ```api.getSelfF()``` and ```api.getCategoriesF()``` _sequentially_. It desugars to

{% highlight scala %}
api.getSelfF().flatMap(apiUser => api.getCategoriesF().flatMap(apiCategories => ...))
{% endhighlight %}

So one waits for the other even though it doesn't need to. Invoking the methods outside of the ```for```-comprehension
solves this.

Likewise, you might also write:

{% highlight scala %}
for {
  ...
  apiFriends <- apiFriendsF(apiUser)
  apiCheckins <- apiCheckinsF(apiUser, apiCategories)
  ...
} yield ...
{% endhighlight %}

But these two can also be done in parallel. Write it this way instead:

{% highlight scala %}
for {
  ...
  (apiFriends, apiCheckins) <- future.join(
    apiFriendsF(apiUser)
    apiCheckinsF(apiUser, apiCategories))
  ...
} yield ...
{% endhighlight %}

The ```future.join``` utility methods are defined like this:

{% highlight scala %}
def join[A, B](a: Future[A], b: Future[B]): Future[(A, B)] = {
  a.join(b)
}

def join[A, B, C](a: Future[A], b: Future[B], c: Future[C]): Future[(A, B, C)] = {
  a.join(b).join(c).map{ case ((a, b), c) => (a, b, c) }
}
{% endhighlight %}

The ```join``` method runs two Futures in parallel and collects their results in a tuple.

### Anti-pattern #4: Not setting up a FuturePool

By default, the executor for Futures runs everything sequentially. In order to get your Futures to run
in parallel threads, you have to set up something like this:

{% highlight scala %}
object future {
  private val pool = FuturePool(java.util.concurrent.Executors.newFixedThreadPool(10))

  def apply[A](a: => A): Future[A] = pool(a)
  def join[A, B](a: Future[A], b: Future[B]): Future[(A, B)] = ...
  def join[A, B, C](a: Future[A], b: Future[B], c: Future[C]): Future[(A, B, C)] = ...
  def groupedCollect[A, B](xs: Seq[A], par: Int)(f: A => Future[B]): Future[Seq[B]] = ...
}
{% endhighlight %}

of course tuning your ```ThreadPoolExecutor``` parameters to suit your case.

OK that's it!


---
layout: post
title: "An effective pattern for programming with Futures"
description: ""
category: 
tags: []
---
{% include JB/setup %}

Twitter's Future library is a beautiful abstraction for dealing with concurrency. However, there are a few
code patterns that seem innocuous and even natural but can cause real trouble in production systems.

### An example

Below is a method from a fictional web application that registers a user by calling the Foursquare API
to get the user's profile info, the their friend graph and their recent check-ins.

{% highlight scala %}
def registerUser(token: String): Future[User] = {
  val api = FoursquareApi(token)

  def apiFriendsF(apiUser: ApiUser): Future[Seq[ApiUser]] = {
    Future.collect(apiUser.friendIDs.map(api.getUserF))
  }

  def apiCheckinsF(apiUser: ApiUser, categoryies: Seq[ApiCategory]): Future[Seq[ApiCheckin]] = {
    ...
  }

  def createDBUser(
      user: ApiUser,
      friends: Seq[ApiUser],
      checkins: Seq[ApiCheckin]): User = {
    db.insert(...)
  }

  for {
    apiUser <- api.getSelfF()
    apiCategories <- api.getCategoriesF()
    apiFriends <- apiFriendsF(apiUser)
    apiCheckins <- apiCheckinsF(apiUser, apiCategories)
  } yield createDBUser(apiUser, apiFriends, apiCheckins)
}
{% endhighlight %}

There are some problems with this code.

### Anti-pattern #1: Doing work in a yield or a map

The last part of the ```for```-comprehension desugars to

{% highlight scala %}
apiCheckinsF(apiUser, apiCategories).map(apiCheckins => createDBUser(apiUser, apiFriends, apiCheckins))
{% endhighlight %}

You should never do blocking work in ```map``` on a Future. Code inside the map runs after the Future
thread completes, but it runs on the scheduler thread, preventing it from doing any more scheduling, which is bad.
Also there is only one such thread, so you're losing an opportunity for parallelism. It's also possible to
cause a deadlock this way.

Instead, do this:

{% highlight scala %}
def createDBUserF(
    user: ApiUser,
    friends: Seq[ApiUser],
    checkins: Seq[ApiCheckin]): Future[User] = Future {
  db.insert(...)
}

for {
  ...
  user <- createDBUserF(apiUser, apiFriends, apiCheckins)
} yield user
{% endhighlight %}

This now desugars to

{% highlight scala %}
createDBUserF(apiUser, friends, checkins).map(user => user)
{% endhighlight %}

which is safe.

So ALWAYS ```yield``` a plain value or a simple computation.

### Anti-pattern #2: Too much parallelism

The method ```apiFriendsF``` creates a future for each item in a list of user IDs and collects the results into a single 
Future:

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

The ```groupedCollect``` utility method can be impemented as follows:

{% highlight scala %}
object future {
  def groupedCollect[A, B](xs: Seq[A], par: Int)(f: A => Future[B]): Future[Seq[B]] = {
    val bsF: Future[Seq[B]] = Future.value(Seq.empty[B])
    xs.grouped(par).foldLeft(bsF){ case (bsF, group) => {
      for {
        bs <- bsF
        xs <- Future.collect(group.map(f))
      } yield bs ++ xs
    }}
  }
}
{% endhighlight %}

The ```par``` parameter lets you specify how much work you want done in parallel. For example, if you specify 5, it will
take 5 items from the list, do them all in parallel, and wait for them to complete before moving on to the next 5 items.

### Anti-pattern #3: Not enough parallelism

This code invokes ```api.getSelfF()``` and ```api.getCategoriesF()``` sequentially when they could be run in parallel:

{% highlight scala %}
for {
  apiUser <- api.getSelfF()
  apiCategories <- api.getCategoriesF()
  ...
} yield ...
{% endhighlight %}

It desugars to

{% highlight scala %}
api.getSelfF().flatMap(apiUser => api.getCategoriesF().flatMap(apiCategories => ...))
{% endhighlight %}

So one waits for the other even though it doesn't need to. The fix is to invoke the methods outside of the
```for```-comprehension.

{% highlight scala %}
val apiUserF: Future[ApiUser] = api.getSelfF()
val apiCategoriesF: Future[Seq[ApiCategory]] = api.getCategoriesF()

...

for {
  apiUser <- apiUserF
  apiCategories <- apiCategoriesF
  ...
} yield ...
{% endhighlight %}

Likewise, we have:

{% highlight scala %}
for {
  ...
  apiFriends <- apiFriendsF(apiUser)
  apiCheckins <- apiCheckinsF(apiUser, apiCategories)
  ...
} yield ...
{% endhighlight %}

These two can also be done in parallel. Write it this way instead:

{% highlight scala %}
for {
  ...
  (apiFriends, apiCheckins) <- Future.join(
    apiFriendsF(apiUser)
    apiCheckinsF(apiUser, apiCategories))
  ...
} yield ...
{% endhighlight %}

The ```join``` method runs multiple Futures in parallel and collects their results in a tuple.

### Anti-pattern #4: Doing blocking I/O without a FuturePool

TODO

{% highlight scala %}
object future {
  private val pool = FuturePool(Executors.newFixedThreadPool(10))
  def apply[A](a: => A): Future[A] = pool(a)
}
{% endhighlight %}

### Conclusion

Here's what we ended up with:

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
    (apiFriends, apiCheckins) <- Future.join(
      apiFriendsF(apiUser)
      apiCheckinsF(apiUser, apiCategories))
    user <- createDBUserF(apiUser, apiFriends, apiCheckins)
  } yield user
}
{% endhighlight %}

Things to note here:

1. Nested methods take plain values and return Futures, for great ```flatMap```ing.
2. All the work is set up ahead of time via ```val```s and nested methods.
3. Everything is "glued" together with a ```for```-comprehension at the end.
4. Parallelism and dependencies are made explicit in the ```for```-comprehension.



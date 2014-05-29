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

### Anti-pattern #1: Blocking in a yield or a map

The last part of the ```for```-comprehension desugars to

{% highlight scala %}
apiCheckinsF(apiUser, apiCategories).map(apiCheckins => 
  createDBUser(apiUser, apiFriends, apiCheckins))
{% endhighlight %}

The problem here is that ```createDBUser``` makes a blocking call to the database.
You should never do blocking work in ```map``` on a Future.
Every Future runs in a thread pool that is (hopefully) tuned for a particular purpose.
Code inside the ```map``` runs on the thread that completes the Future. 
So you're putting work in a thread pool that wasn't designed to handle that work.

Furthermore, when you're dealing with Futures composed from other Futures, it's often hard to tell by inspection which
Future will be the last to complete (and whose thread pool will run the ```map``` code).
It's frequently not the "outermost" Future. For example:

{% highlight scala %}
val outermostFuture1: Future[Int] = {
  val runsInThreadPoolA: Future[Int] = ...
  val runsInThreadPoolB: Future[Int] = ...
  for {
    a <- runsInThreadPoolA
    b <- runsInThreadPoolB
  } yield a+b
}

outermostFuture1.map(i => /* where do I run?? */)
{% endhighlight %}

It doesn't even have to be deterministic:

{% highlight scala %}
val outermostFuture2: Future[Int] = {
  val runsInThreadPoolA: Future[Int] = ...
  val runsInThreadPoolB: Future[Int] = ...
  for {
    (a, b) <- Future.join(runsInThreadPoolA, runsInThreadPoolB)
  } yield a+b
}

outermostFuture2.map(i => /* where do I run?? */)
{% endhighlight %}

It's also possible that the Future completes *before* you call ```map``` — in which case the work inside the ```map```
happens in the main thread. This is bad if your callers expect you to to return instantly with a Future.

{% highlight scala %}
def thisActuallyBlocks(a: Int): Future[Int] = {
  val anIntF: Future[Int] = computeSomethingF(a)
  // ... some more stuff ...
  anIntF.map(i => somethingThatBlocks(i))
}
{% endhighlight %}

It's also possible to cause a deadlock (and yes we've seen this in production) if the code inside the ```map```
calls ```Await``` on another thread in the same thread pool — but again, it's hard to know what thread pool that is.

So instead, set up your own thread pool for blocking work:

{% highlight scala %}
object future {
  private val pool = FuturePool(Executors.newFixedThreadPool(10))
  def apply[A](a: => A): Future[A] = pool(a)
}
{% endhighlight %}

And use it like this:

{% highlight scala %}
def createDBUserF(
    user: ApiUser,
    friends: Seq[ApiUser],
    checkins: Seq[ApiCheckin]): Future[User] = future {
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

So ALWAYS ```yield``` a plain value or a simple computation. If you have blocking work, wrap it in a ThreadPool-backed
Future and ```flatMap``` it.

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

The ```groupedCollect``` helper method can be impemented as follows:

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
It's also nice that the ```join``` explicitly documents that the two calls will happen in parallel.

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



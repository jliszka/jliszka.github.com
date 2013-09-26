---
layout: post
title: "Insertion sort is dual to bubble sort"
description: ""
category: 
tags: [ "code" , "backwards programming" ]
---
{% include JB/setup %}

I noticed recently that [insertion sort](http://en.wikipedia.org/wiki/insertion_sort) is
[bubble sort](http://en.wikipedia.org/wiki/Bubble_sort) backwards. Or inside out. Or something.

Both algorithms can be expressed as a main function that calls a recursive helper. Let's
take a look at the main functions first.

### The main functions

Here's the code:

{% highlight scala %}
def insertionSort[A <: Ordered[A]](xs: List[A]): List[A] = {
  xs match {
    case Nil => Nil
    case h :: t => {
      val s = insertionSort(t)
      insert(h, s)
    }
  }
}
{% endhighlight %}

```insertionSort``` sorts a list by inserting the head of the list into the recursively sorted tail, in such a way that it remains sorted.

{% highlight scala %}
def bubbleSort[A <: Ordered[A]](xs: List[A]): List[A] = {
  xs match {
    case Nil => Nil
    case xs => {
      val (h, t) = bubble(xs)
      val s = bubbleSort(t)
      h :: s
    }
  }  
}
{% endhighlight %}

```bubbleSort``` sorts a list by bubbling the smallest element to the front of the list and recursively sorting the tail.

It's not obvious from the code that these functions are backwards versions of each other,
but look at their data flow diagrams:

<!-- more -->

![main function data flow](/assets/img/main.png)

They are exactly the same, except with the arrows going the other way.

Of course you would also want each box to be the "backwards" version of its corresponding box in the other function.
This is pretty obviously true for ```cons``` and ```decons``` — one constructs a list from a head and a tail,
and the other deconstructs a list into a head and a tail.
And by assumption, the recursive call to
```bubble sort``` is the "backwards" version of the corresponding recursive call to ```insertion sort```.

All that's left is to show that this is true for helper functions — that ```bubble``` is ```insert``` backwards.

### The helper functions

Here's the code:

{% highlight scala %}
def insert[A <: Ordered[A]](x: A, xs: List[A]): List[A] = {
  xs match {
    case Nil => x :: Nil
    case h :: t => {
      val (a, b) = sort(x, h)
      val r = insert(b, t)
      a :: r
    }
  }
}
{% endhighlight %}

```insert```'s job is to insert an item into an already-sorted list in such a way that the list remains sorted.

{% highlight scala %}
def bubble[A <: Ordered[A]](xs: List[A]): (A, List[A]) = {
  xs match {
    case h :: t => {
      val (x, r) = bubble(t)
      val (a, b) = sort(x, h)
      (a, b :: r)
    }
  }
}
{% endhighlight %}

```bubble```'s job is to bubble the smallest item up to the front of the list and return that item plus the rest of the list.

The data flow diagrams of these functions make it totally clear that they are the same function, only one has the
arrows reversed and the boxes running backwards:

![helper function data flow](/assets/img/helper.png)

The only thing left is this ```sort``` method, which takes 2 arguments and returns them in
sorted order. Which I guess is the same if you run it backwards?

{% highlight scala %}
def sort[A <: Ordered[A]](a: A, b: A): (A, A) = {
  if (a < b) (a, b) else (b, a)
}
{% endhighlight %}

So, there you have it. Aside from the ```Nil``` cases and the question of ```sort``` being its own opposite,
if you take a machine that does insertion sort and run it in reverse, you get a machine that does bubble sort.

I'm pretty sure this fits the categorical definition of a dual, but my Category theory isn't strong enough to say for sure.

### Are there any other sorting algorithms that are duals?

Yes, I believe [Merge sort](http://en.wikipedia.org/wiki/Merge_sort) and 
[Quicksort](http://en.wikipedia.org/wiki/Quicksort) are duals, but I haven't been able to get it to work out.

Merge sort looks like this:

1. Split the list in half
2. Recursively sort each half
3. Merge the two halves back together

And Quicksort looks like this:

1. Partition the list into a list of smaller items and a list of larger items
2. Recursively sort each list
3. Concatenate them back together

Clearly, the "split" and "concatenate" steps are dual, and the recursive calls are dual by assumption.
The "merge" and "partition" steps also seem like they should be dual to each other — one
interleaves 2 lists to form 1 list, and the other distributes the elements of 1 list into 2 other lists.
But I haven't been able to formulate them in such a way that they are really "backwards" versions of each other.

It's possible that "merge" is actually dual to a function that extracts an increasing subsequence from a list, as
in [strand sort](http://en.wikipedia.org/wiki/Strand_sort). If that turns out to be true, then strand sort is its own dual.
That would be interesting to investigate.

### Shouldn't a backwards sort... unsort a list?

Well yeah, it should, but it can't. Sorting a list destroys information. You can pinpoint where that happens:
the ```sort``` function. If you give it ```(4, 3)``` it will output ```(3, 4)```, but if you run it backwards,
it can't know whether to turn ```(3, 4)``` into ```(4, 3)``` or ```(3, 4)``` without some additional information.
To think of it another way: a given list has only one sorted ordering but a very large number of unsorted orderings.
One deterministic function can't turn a sorted list into each of the unsorted lists you could have started with.

So these backwards functions are backwards in every respect except for the part that destroys information.

### Can this be done automatically?

Can you write a function that takes another function (or a suitable description thereof) as input and turns it
inside out? Can we get new algorithms for free just by turning existing ones on their head? What happens if you
run Dijkstra's algorithm backwards? I don't know!



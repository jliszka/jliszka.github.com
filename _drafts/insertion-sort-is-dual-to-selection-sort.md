---
layout: post
title: "Insertion Sort is dual to Selection Sort"
description: ""
category: 
tags: [ "code" ]
---
{% include JB/setup %}

I happened to notice recently that [selection sort](http://en.wikipedia.org/wiki/Selection_sort)
is [insertion sort](http://en.wikipedia.org/wiki/insertion_sort) backwards. Or inside out. Or something.

Both algorithms can be expressed as a main function that calls a recursive helper. Let's
take a look at the main functions first.

### The main functions

```insertionSort``` sorts a list by inserting the head of the list into the recursively sorted tail, in such a way that it remains sorted.
```selectionSort``` sorts a list by extracting the smallest element from the list and consing it onto the front of the recursively sorted tail.

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

def selectionSort[A <: Ordered[A]](xs: List[A]): List[A] = {
  xs match {
    case Nil => Nil
    case xs => {
      val (h, t) = select(xs)
      val s = selectionSort(t)
      h :: s
    }
  }  
}
{% endhighlight %}

Now let me show you these exact same algorithms in the form of data flow diagrams.
The boxes are functions, and the edges are data flow, labeled with the variable name that carries that piece of data.

![main function data flow](/assets/img/main.png)

They are exactly the same, except with the arrows going the other way!
Of course you would also want each box to be the "backwards" version of its corresponding box in the other function.
This is pretty obviously true for ```cons``` and ```decons``` — one constructs a list from a head and a tail,
and the other deconstructs a list into a head and a tail.
We can also invoke the induction hypothesis and claim that the recursive call to
```selection sort``` is the "backwards" version of the corresponding recursive call to ```insertion sort```.

All that's left is to show that this is true for helper functions — that ```select``` is ```insert``` backwards.
Let's take a look.

### The helper functions

```insert```'s job is to insert an item into an already-sorted list in such a way that the list remains sorted.
```select```'s job is to pull the smallest item out of a list and return that item plus the rest of the list.

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

def select[A <: Ordered[A]](xs: List[A]): (A, List[A]) = {
  xs match {
    case h :: t => {
      val (x, r) = select(t)
      val (a, b) = sort(x, h)
      (a, b :: r)
    }
  }
}
{% endhighlight %}

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
if you take a machine that does insertion sort and run it in reverse, you get a machine that does selection sort.

I'm pretty sure this fits the categorical definition of a dual, but my Category theory isn't strong enough to say for sure.

### Are there any other sorting algorithms that are duals?

Yes, I believe [Merge sort](http://en.wikipedia.org/wiki/Merge_sort) and 
[Quicksort](http://en.wikipedia.org/wiki/Quicksort) are dual to each other, but I haven't been able to get it to work out.

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

### Can this be done automatically?

Can you write a function that takes another function (or a suitable description thereof) as input and turns it
inside out? Can we get new algorithms for free just by turning existing ones on their head? What happens if you
run Dijkstra's algorithm backwards?

I don't know! Good questions!









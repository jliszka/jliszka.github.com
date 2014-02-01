---
layout: post
title: "Lies, damned lies, and <i>p</i>-values"
description: ""
category: 
tags: [ "probability" ]
---
{% include JB/setup %}

degrees of freedom
- searching for signficance adds degrees of freedom

multiple experiments at once: genetics testing. just as cheap to run 1000 experiments as 1 experiment.
what is the probability you will find a significant result at random?

{% highlight scala %}
case class Patient(hasDisease: Boolean, genes: List[Boolean])

def genes(n: Int) = uniform.repeat(n)
def patient(diseasePrevalence: Double, genePrevalence: List[Double]) = {
  for {
    hasDisease <- tf(diseasePrevalence)
    genes <- sequence(genePrevalence.map(tf))
  } yield Patient(hasDisease, genes)
}

def corr(xs: List[(Boolean, Boolean)]) = {
  val n = xs.size
  val pA = xs.count(_._1).toDouble / n
  val pB = xs.count(_._2).toDouble / n
  val stdevA = math.sqrt(pA * (1 - pA))
  val stdevB = math.sqrt(pB * (1 - pB))
  def toInt(b: Boolean) = if (b) 1 else 0
  val cov = xs.map{ case (a, b) => (toInt(a) - pA) * (toInt(b) - pB)}.sum / n
  cov / (stdevA * stdevB)
}

def experiment(nGenes: Int, nPatients: Int) = {
  val diseasePrevalence = 0.5
  for {
    genePrevalence <- genes(nGenes)
    patients <- sequence(List.fill(nPatients)(patient(diseasePrevalence, genePrevalence)))
  } yield patients
}

def analyze(patients: List[Patient]) = {
  val nGenes = patients.head.genes.size
  (0 to nGenes-1).map(g => {
    corr(patients.map(p => (p.hasDisease, p.genes(g))))
  }).max
}
{% endhighlight %}

diminishing effect size
publication bias + meta-analyses
bayesian hypothesis testing: where do priors come from? is 50/50 reasonable?
if it hasn't already been discovered, it's less likely to be true (prior)
all the true and obvious facts have been discovered already. new hypotheses are less likely to be true.

http://pss.sagepub.com/content/early/2013/11/07/0956797613504966.full.pdf

http://www.newyorker.com/reporting/2010/12/13/101213fa_fact_lehrer

{% highlight scala %}
def meanstdev(xs: List[Double]): (Double, Double) = {
  val n = xs.size
  val mean = xs.sum / n
  val stdev = math.sqrt(xs.map(_ - mean).map(x => x*x).sum / n)
  (mean, stdev)
}

val d1 = normal * 20
val d2 = d1 + 10

def d(n: Int) = {
  for {
    x1s <- d1.repeat(n)
    x2s <- d2.repeat(n)
  } yield {
    val (m1, s1) = meanstdev(x1s)
    val (m2, s2) = meanstdev(x2s)
    val diff = m2 - m1
    val stderr = math.sqrt((s1*s1 + s2*s2) / n)
    val p = (normal * stderr).pr(_ > diff)
    (p, diff - 1.96*stderr, diff + 1.96*stderr)
  }
}
{% endhighlight %}

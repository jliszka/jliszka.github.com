---
layout: post
title: "Painless, effective peer reviews"
description: ""
category: 
tags: []
---
{% include JB/setup %}

Peer reviews are the worst. Most people I know dread the prospect of having to write one. At many companies, the bulk of
the peer review process comes in the form of 2 or 3 free-response type questions. There might be other parts to it, but
this is what takes most of the time and causes most of the stress. It's not uncommon for someone to take 4 or 5 hours to
write a single peer review, and due to procrastination this can stretch out over a period of a week or more.

I think this happens for a combination of reasons. Mostly:

- **They don't know what to write.** It's hard to come up with suggestions or advice for stellar co-workers.

- **It's difficult and uncomfortable to write down honest critical feedback.** No one wants to offend their peer,
so they soften the language and word everything very carefully to avoid the possibility of misinterpretation. Careful
wording and editing takes time!

- **They're just slow writers.** In the tech industry at least, many people got through college having had to suffer
through only one or two writing classes. They're simply out of practice or haven't learned the writing-specific
productivity skills that folks with a more well-rounded education are adept at.

- **It's so easy to procrastinate.** Sitting at a computer trying to write, there are literally thousands of distractions
one keystroke away.

The result of this is that you get two kinds of reviewers: those who give thorough, quality feedback but take forever doing it,
and those who throw a few thoughts together quickly but don't produce much in the way of insight or helpful feedback.

You could try instituting multiple-choice style reviews (of the "Strongly agree, Somewhat agree, Neutral, Somewhat
disagree, Strongly disagree" variety), and while you'll get responses back faster from everyone, they lack nuance,
examples, advice, constructive criticism, and really anything that would qualify as helpful feedback. I mean, if your
goal is not to be helpful, go for it. Some companies only care about evaluating their employees, not helping them get
better. But that's not what this article is about.

### Goals

Before I go any further, I want to clearly lay out the goals of a peer review, just so there's no confusion about what
problems I'm trying to solve. The goals are:

1. to produce helpful feedback for the employee, and

2. to not take forever.

Notably absent are notions of evaluation and calibration. Those can be accomplished pretty easily through mulitple-choice
type surveys.

So if we're just talking about helpful feedback, you would think that there's a natural trade-off between time and
quality — but you would be wrong! There is a method that consistently produces high-quality, honest, critical,
insightful peer review feedback, and you can get it done in about an hour.

### The interview method

Here's how it works, in 5 easy steps:

1. **Schedule a meeting.** The manager conducting the review sets up a 30 minute 1-on-1 meeting with the peer reviewer.
_Time: 30 seconds_.

2. **Prepare notes.** Before the meeting, the peer reviewer takes a few minutes to jot down some notes about the
reviewee, going through emails, code commits, and their own recollections. _Time: 10 minutes_.

3. **Interview.** During the meeting, the reviewer talks about the reviewee, and the manager writes down everything they
say, as verbatim as possible. The manager guides the discussion by asking clarifying questions or bringing up broad
topics (think "How would you characterize Joe's impact on the organization?" not "Joe breaks the build all the time,
what do you think about that?"). _Time: 30 minutes_.

4. **Edit.** After the meeting, the manager turns the notes into written, readable English, of the quality that you
would see in a regular written review. This consists of two parts: copy editing (fixing typos, supplying connecting
words, expanding abbreviations, removing redundancies) and organization (rearranging the sentences and paragraphs into
common themes — people do tend to ramble). _Time: 15 minutes_.

5. **Get approval.** The manager shows the finished review to the reviewer for approval. The reviewer makes sure that
their thoughts are being accurately represented and that they are comfortable with the content of the review. _Time: 5
minutes_.

You're done! Total elapsed time: one hour. Total person-hours: one hour and 30 minutes.

### Why this is great

It's efficient. There's nothing like getting 3 or 4 hours of your life back, and given the choice, potential reviewers
will jump for it every time, and will thank you for it. And you're not sacrificing any fidelity — written reviews
produced this way are of similar or greater quality than those produced by traditional means.

I've found this to be a surprisingly effective way of getting honest feedback out of people. For some
reason, people filter their thoughts when they write, but not so when they speak. Certain things that they would
hesitate to write down, they have no trouble saying aloud.

I also tend to get a lot more volume from people who don't think they have much to say, or who would normally write very
little. I think one reason for this is that writing interrupts your train of thought. Worse, by the time you finish
writing the first half of your thoughts, you've forgotten the second half.

So much of writing is putting yourself in your reader's shoes and handling possible objections or misinterpretations —
you're not going to be there when they read it, so you have to cover your bases. This is a taxing process. Having
someone there to give you immediate feedback short circuits much of it. The manager will do this instinctively by giving
subtle non-verbal cues to the reviewer that lets them know that what they're saying makes sense.

### Common objections

**Isn't this more work for the manager conducting the review?**<br/> Yes, but it's mostly mindless work. Copy editing is
not the same thing as creating insightful sentences from whole cloth; the manager is polishing and rearranging existing
material, not creating it. It does certainly involve more clock time for the manager, about an hour per reviewer.

But the upside is that it dramatically decreases the load on peer reviewers, by a factor of 3 or more. That frees them
up to do their actual job — which, to me, is what being a [servant-leader](http://en.wikipedia.org/wiki/Servant_leadership)
is all about. Besides, if I can't spend 3-5 hours per report per *year* as a manager to get them the best feedback I can,
what are they paying me for?

**Won't the manager bias the reviewer during the interview?**<br/>
It is a theoretical concern, but in practice the manager is too busy typing to do much else. There is certainly room for
a malicious manager to do some damage here. But if you don't trust your managers, you have bigger problems, right?

**Aren't peer reviewers going to shy away from being critical in person?**<br/>
This is what surprised me the most. It turns out that critical feedback flows much more freely in a
face-to-face discussion than it does in writing. I can't really explain it, except that perhaps people are wary of
committing criticism to writing. When they see it on the page in black and white, attributed to them, they freak out a
little bit and change it. When speaking off the cuff, their thoughts tend to come out less filtered.

One peer reviewer, looking back at the notes I had taken after a particularly critical review, remarked to me, "Wow,
there's no way I would have written these things down. It's brutally honest and blunt — but I'm happy with it, because
this is how I felt, this is what I said."

### Pro tips for managers

**Keep the conversation in a helpful place.** The idea is to find ways to help people improve. This is what marks the
difference between evaluation and feedback. If you're hearing a lot of unconstructive complaining, you can keep it on
track by asking, "what should X be doing differently here?" or "so what's your advice for X?"

**Ask questions to keep things moving along.** Most of the time, reviewers have no shortage of things to say, but sometimes
a little prompting goes a long way. For example:

- "Can you elaborate on that?"
- "Can you give me an example of that?"
- "Can you talk about X's impact on the org?"
- "Is X the best engineer you've ever worked with? What could X do to be even better?"
- "What the next level for X?"
- "What's the one piece of advice you have for X?"
- "Who else should I talk to about X?"
- "What else?"

**Editing is critical.**
There's a big difference between the way people talk and the way people read. Bridging the gap is your job as the manager
conducting the review. The goal is to make the prose as readable as possible while retaining the original meaning. This
means that paraphrasing is sometimes necessary, but you should avoid it if you can. More commonly, you'll want to trim down
rambling or duplicated sentences or ideas. When people talk, they often retread over the same idea multiple times using
different words. Feel free to pick one or two of these and delete the rest.

But most often, you'll just be turning your notes into Proper English Sentences. To give you an idea what I mean, here
is what I typed during one actual interview:

> "very storng design sense about how these things should work, can comm htem effectively and clearly. we don’t nec
> agree, but it’s easy for us to id that quickly and come to a soluteiom"

And here's the final result:

> "He has a very strong design sense about how things should work and can communicate them effectively and clearly. We
> don't always necessarily agree, but it's easy for us to identify that and come to a solution."

Interview:

> this works and this works, but this one is better because it will let us do x y and z down the road 

Final:

> There are two solutions that work, but one of them is better because it allows us to do more things down the road.

That one involved some paraphrasing. It improved clarity without changing the meaning. But I think that's as far as
you'll want to go in paraphrasing.

Luckily, the fallback is that the reviewer gets final say as to what goes into their review. If you accidentally misrepresent
them in what you type up, they have the opportunity to correct it.

**Reorganizing is critical.**
This is a step beyond editing. People retread the same topics and touch on the same themes throughout the interview.
You'll just want to group together things that are related. You can do it by topic (technical skill, communication,
leadership, getting things done, detail-oriented) or by subject (top accomplishments, things they're good at, things to
work on). But the point is that the review should lay out a coherent story and should not jump around between topics,
even if that's what the reviewer did during the interview. It's more important that the review is delivered effectively
than that it is 100% true to what the reviewer said in what order they said it.

### Conclusion

I've been conducting annual reviews this way for almost a year, with overwhelmingly positive results. Reviewers
uniformly and enthusiastically prefer it, and reviewees don't notice the difference (I always give them the choice of
how they would like their peer reviews done). The only times it hasn't gone well were my own fault, due to insufficient
editing of my notes into a coherent review.

I think the fundamental reason this is so effective is that humans are just wired to speak to other humans. When you
think about it, writing things down is a very unnatural act. If you want to get quick access to the thoughts in someone's
head, you talk to them in person. There's something about just having another person in the room that triggers
something in your brain that enables effective communication.

Try it out, let me know what you think!


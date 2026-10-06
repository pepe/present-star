title: How We Do Seminars
author: Josef Pospíšil
date: 2026/27
---

# Enter pepe

---
# How do my LLMs see me

**Curious to the point of trouble.**

- I rarely accept *“that’s just how it is.”*
- I like turning problems into systems.
- I connect ideas that probably were not introduced to each other.
- I prefer understanding over memorising.
- I will happily rebuild the whole model if one assumption looks wrong.
- I sometimes make simple things unnecessarily complicated.

And apparently I talk to AI until **both sides learn something**.

---

# Seminars are not optional

You do **have** to come.

My part of the deal:

> I will try my best to make it worth coming.

Useful, understandable —  
and hopefully entertaining.

---

# If you come…

…please let the Seminar work.

- Listen to each other.
- Do not interrupt without a reason.
- Give others space to think.
- Help us keep the room focused.

This is not about silence.

It is about **attention**.

---

# Interrupt me when it matters

Something does not make sense?

**Tell me.**

A definition is unclear?  
An example seems wrong?  
I skipped a step?

Ask.

Very often, if **you** did not understand it,  
someone else did not either.

---

# Be proactive

Do not treat the Seminar as a video stream.

Question things.  
Try examples.  
Challenge assumptions.  
Make connections.

Data modelling is much more fun  
when we actually **think together**.

---

# There will be medals 🏅

Some achievements will earn you medals.

Exactly what they are for?

You will find out.

---

# One more thing…

This is the **first run of this course for me too**.

Some things will work brilliantly.

Some things probably will not.

If something needs changing, we change it.

> No worries. We’ll make it.
---
# Q&A
===
title: From a Story to a Data Model
author: Josef Pospíšil
date: 2026-09-29
---
# OPM Cheatsheet

## Object-Process Methodology

For now, we need only a few ideas:

* **objects**
* **processes**
* **states**
* **relationships**

The goal:

> describe the world before choosing a database model
---
# Object

An **object** is something that exists.

Examples:

```text
Student
Course
Enrollment
Invoice
Book
Reservation
```

In an OPM diagram:

> object = rectangle
---
# Process

A **process** changes something.

Examples:

```text
Enrolling
Paying
Booking
Registering
Shipping
```

In an OPM diagram:

> process = ellipse
---
# A useful test

Ask:

> Can it exist?

Probably an **object**.

Ask:

> Does it create, destroy, or change something?

Probably a **process**.
---
# Objects have states

An object may exist in different **states**.

For example:

```text
Enrollment
  pending
  active
  completed
  cancelled
```

A process may change one state into another.
---
# Transformation

A process can:

* create an object
* destroy an object
* change its state

For example:

```text
Enrolling
        ↓
Enrollment
```

`Enrolling` creates an `Enrollment`.
---
# State change

Consider:

```text
Enrollment

pending → active
```

What caused the change?

```text
Confirming
```

So we can think:

```text
pending Enrollment
        ↓
    Confirming
        ↓
active Enrollment
```
---
# Objects can be related

Not everything is a process.

Some relationships describe structure:

```text
Student — has — StudentID

Course — has — CourseCode

Course — is part of — Programme
```

These relationships describe how things are connected.
---
# Structure vs behaviour

OPM combines two views.

**Structure**

```text
Student
Course
Enrollment
```

---
# Structure vs behaviour

**Behaviour**

```text
Enrolling
Grading
Cancelling
```
---
# Structure vs behaviour


Ask both:

> What exists?

and:

> What happens?
---
# Our university example

Objects:

```text
Student
Course
Enrollment
```

Process:

```text
Enrolling
```

A possible story:

```text
Student
   \
    Enrolling → Enrollment
   /
Course
```
---
# Say it as a sentence

A good model should also make sense in ordinary language.

For example:

> Enrolling yields Enrollment.

> Enrollment relates a Student to a Course.

If you cannot explain the diagram as a sentence:

**the model probably needs more thought.**
---
# Start your project

Do not begin with tables.

Begin with the world.

Write down:

1. important **objects**
2. important **processes**
3. important **states**
4. important **relationships**
---
# Ask these questions

For every object:

> What is it?

> What states can it have?

For every process:

> What does it change?

> What does it require?

> What does it create?
---
# Keep it small

Your first model does **not** need everything.

Start with:

* 3–6 important objects
* 2–4 important processes
* only meaningful states
* only important relationships

Then refine it.
---
# Today

For your project domain:

1. describe the world in a few sentences
2. draw the first OPM model
3. identify objects and processes
4. add states where useful
5. explain the model to another person

> Model the world first.  
> Choose the database representation later.

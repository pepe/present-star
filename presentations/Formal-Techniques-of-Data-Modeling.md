title: Data Types, Data Models and Formality
author: Josef Pospíšil
date: 2026-09-29
---
# Formal Techniques of Data Modelling

## Data Types, Data Models and Formality

**EIED5E / INFOAN**

How can we describe information about a world precisely enough that we can reason about the model?
---
# What is data?

## 42

Is it:

* an integer?
* a string?
* an age?
* an identifier?
* a course code?
* an answer?
---
# Representation is not meaning

`42`

does not tell us what it means.

Meaning depends on:

* context
* domain
* interpretation
* model

> Data exists within a model.
---
# Alice

Suppose Alice is a student.

The real Alice has:

* a history
* friends
* interests
* height
* opinions
* courses

What should our model preserve?
---
# A student record

```text
Student
  id: 1042
  name: Alice
```

This is not Alice.

It is a **representation of Alice** for some purpose.
---
# One thing, many representations

```text
1042,Alice
```

```json
{
  "id": 1042,
  "name": "Alice"
}
```

```text
Student(1042, "Alice")
```

The represented thing may stay the same while the representation changes.
---
# Modelling is abstraction

A model deliberately preserves some distinctions and ignores others.

For our university model:

* Student vs Course matters
* StudentID vs CourseCode matters
* enrolled vs not enrolled matters

Eye colour probably does not.
---
# Value

A **value** is a particular element represented in a model.

Examples:

```text
42
"Alice"
"DB101"
A
```

But a value alone tells us very little.
---
# Type

Compare:

```text
42 vs "42"
```

One possible interpretation:

```text
42   ∈ Integer
"42" ∈ String
```

A type tells us what kind of value we are dealing with.
---
# But type is more than storage

Suppose:

```text
StudentID = 1042
```

It may be stored as an integer.

But is this meaningful?

```text
1042 + 2031 = 3073
```

What would adding two Student IDs mean?
---
# Semantic types

`StudentID`

and

`Integer`

may share the same representation.

But they do not necessarily support the same meaningful operations.

> Types express distinctions in meaning, not only representation.
---
# Domain

A **domain** is a set of admissible values.

For example:

```text
Grade = {A, B, C, D, E, F}
```

or

```text
Boolean = {true, false}
```

Attributes draw their values from domains.
---
# Attributes

```text
Student
  id
  name
```

can become:

```text
id   : StudentID
name : String
```

Now the model says more than just "Student has two fields".
---
# Two different questions

> What can exist?

versus

> What exists now?

These are different modelling questions.
---
# Schema

A **schema** describes possible valid structures.

```text
Student
  id   : StudentID
  name : String

Course
  code  : CourseCode
  title : String
```

It describes what *may* exist.
---
# Enrollment

```text
Enrollment
  student : Student
  course  : Course
  grade   : Grade
```

The schema describes the shape of an enrollment.

It does not tell us who is enrolled now.
---
# Instance

One possible current state:

```text
Students
1042  Alice
1077  Bob

Courses
DB101  Database Systems
TI201  Theoretical Informatics
```
---
# Another part of the instance

```text
Enrollments
Alice  DB101  B
Alice  TI201  A
Bob    DB101  C
```

This is one particular state allowed by the schema.
---
# Schema vs instance

Schema:

```text
Student(id : StudentID, name : String)
```

Instance:

```text
Student(1042, "Alice")
Student(1077, "Bob")
```

> Schema: what can exist  

> Instance: what exists now
---
# What is a data model?

A data model is more than a diagram.

A useful data model defines:

1. structure
2. constraints
3. operations
4. semantics
---
# Structure

Our model contains things such as:

```text
Student
Course
Enrollment
```

---
# Structure
## contd.

and properties such as:

```text
Student.id
Student.name
Course.code
Enrollment.grade
```

Structure tells us what can be represented.
---
# Constraints

Not every structurally possible state should be valid.

For example:

* Student IDs are unique
* every enrollment refers to an existing student
* every enrollment refers to an existing course
* `grade ∈ Grade`
---
# Operations

A model also supports operations.

For example:

* find a student
* select students
* enrol a student
* assign a grade
* transform a representation

A formal question:

> Does an operation preserve validity?
---
# Informal modelling

Consider:

```text
Student -------- Course
```
---
# Informal modelling
## contd.

What does the line mean?

* studies?
* teaches?
* likes?
* is enrolled in?
* has access to?

The drawing alone is ambiguous.
---
# Formal modelling

A formal model makes important things explicit.

It gives us:

* syntax
* semantics
* rules
* constraints

So that different readers can reason about the same model.
---
# Syntax

**Syntax** asks:

> What expressions are valid?

For example:

```text
name : Student -> String
```

has a particular form.
---
# Semantics

**Semantics** asks:

> What does the expression mean?

```text
name : Student -> String
```

means that every student is associated with a string representing their name.

Syntax gives form.

Semantics gives meaning.
---
# Why formality?

Once a model is precise, we can ask:

* Is the model consistent?
* Is this state valid?
* Does one constraint imply another?
* Are two models equivalent?
* Does a transformation lose information?
* Does an operation preserve validity?
---
# One world, two models

Relational representation:

```text
STUDENT(StudentID, Name)

COURSE(CourseCode, Title)

ENROLLMENT(StudentID, CourseCode, Grade)
```

One possible model of our university world.
---
# Object representation

```text
Student
  id
  name
  enrollments

Course
  code
  title
  students
```

Same domain.

Different modelling choices.
---
# Compare the models

Ask:

* What becomes explicit?
* What becomes implicit?
* Where are relationships represented?
* Which operations feel natural?
* Which constraints are easy to express?

> The world may remain the same while the model changes.
---
# From pictures to mathematics

Instead of saying:

```text
Student has a name
```

we can write:

```text
name : Student -> String
```

This treats an attribute as a mathematical function.
---
# Functions

We can write:

```text
id    : Student -> StudentID
name  : Student -> String

code  : Course -> CourseCode
title : Course -> String
```

Functions give attributes precise mathematical meaning.
---
# Relationships

Enrollment connects students and courses.

We can write:

```text
Enrollment ⊆ Student × Course
```

An enrollment is then a pair:

```text
(student, course)
```
---
# Example

```text
(Alice, DB101) ∈ Enrollment
```

means:

Alice is enrolled in Database Systems.

The informal relationship now has a mathematical representation.
---
# Adding grade

We can extend the relation:

```text
Enrollment ⊆ Student × Course × Grade
```

For example:

```text
(Alice, DB101, B) ∈ Enrollment
```
---
# What did mathematics buy us?

We moved from:

```text
Student -------- Course
```

to:

```text
Enrollment ⊆ Student × Course
```
---
# What did mathematics buy us?
## contd.

Now we can reason about:

* membership
* uniqueness
* constraints
* transformations
* equivalence
---
# Functions are everywhere

We have written:

```text
name : Student -> String
```

But what exactly is a function?

* a mapping?
* a rule?
* an expression?
* a value?
* a computation?
---
# Can a function be data?

Consider:

```text
f(x) = x + 1
```

Can we represent the function itself?

Can a function take another function as input?

Can a function return a function?
---
# Next: λ-calculus

Lambda calculus begins with a radical idea:

> Functions can themselves be represented as expressions.

For example:

```text
λx.x
```

or

```text
λx.x + 1
```

We will start there next time.
---
# Keep these distinctions

* reality vs representation
* value vs type
* schema vs instance
* syntax vs semantics
* structure vs meaning
* informal vs formal
* model vs realization
---
# Back to 42

## 42

What would you now need to know before you could say what it means?

> Representation alone is not enough.
---
# Q&A

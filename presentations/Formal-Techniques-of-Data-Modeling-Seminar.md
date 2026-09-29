title: From a Story to a Data Model
author: Josef Pospíšil
date: 2026-09-29
---
# Formal Techniques of Data Modelling

## Seminar 1

**From a Story to a Data Model**

Today we will model one small world in several ways.
---
# What are seminars for?

Lectures give you:

* concepts
* formal tools
* theory

Seminars are where we:

* use them
* test them
* break things
* compare solutions
---
# The semester journey

```text
real-world problem
        ↓
conceptual model
        ↓
relational model
        ↓
SQL database
```

And also:
---
# The semester journey
## contd.

```text
real-world problem
        ↓
conceptual model
        ↓
graph model
        ↓
Neo4j
```

> Same world. Different models.
---
# Our small world

Alice and Bob are students.

Alice studies:

* Database Systems
* Theoretical Informatics

Bob studies:

* Database Systems
---
# More facts

Database Systems has the code:

```text
DB101
```

Theoretical Informatics has the code:

```text
TI201
```

Students may attend several courses.

Courses may have several students.
---
# More rules

* every student has a unique student ID
* every course has a unique course code
* an enrollment belongs to a semester
* an enrollment may contain a grade
* a student cannot enroll in the same course twice in the same semester
---
# Your turn

Read the description again.

Find:

1. **things**
2. **properties**
3. **connections**
4. **rules**

Work in pairs.
---
# Things

Possible candidates:

```text
Student
Course
Enrollment
```

Are all three really "things"?

Or is one of them something else?
---
# Properties

Possible properties:

```text
Student
  id
  name

Course
  code
  title
```
---
# Properties
## contd.

```text
Enrollment
  semester
  grade
```

Question:

> Why does `grade` belong to Enrollment rather than Student?
---
# Connections

A first sketch:

```text
Student --- Enrollment --- Course
```

Now ask:

* what does each connection mean?
* can there be more than one?
* what information belongs to the connection?
---
# Where does the grade belong?

Suppose:

```text
Alice received B in DB101
```

Should we model this as:

```text
Student
  name: Alice
  grade: B
```
---
# Where does the grade belong?

or as:

```text
Enrollment
  student: Alice
  course: DB101
  grade: B
```

Why?
---
# Model vs data

Let us create some actual data.

```text
Students

1042  Alice
1077  Bob
```

Is this the model?

Or an example of the model?
---
# Courses

```text
Courses

DB101  Database Systems
TI201  Theoretical Informatics
```

This describes one current state.
---
# Enrollments

```text
Enrollments

1042  DB101  2026W  B
1042  TI201  2026W  A
1077  DB101  2026W  C
```

What is each column telling us?
---
# Two different levels

Schema:

```text
Student
  id   : StudentID
  name : String
```

Instance:

```text
1042  Alice
1077  Bob
```
---
# Schema vs instance

> Schema: what can exist

> Instance: what exists now

We will return to this distinction many times.
---
# Relational model

Let us represent the same world as relations.

```text
STUDENT(
  StudentID,
  Name
)
```
---
# Relational model
## contd.

```text
COURSE(
  CourseCode,
  Title
)

ENROLLMENT(
  StudentID,
  CourseCode,
  Semester,
  Grade
)
```
---
# What must be unique?

Think before answering.

In `STUDENT`:

```text
StudentID
```

In `COURSE`:

```text
CourseCode
```

What about `ENROLLMENT`?
---
# Enrollment uniqueness

A student may attend the same course in different semesters.

So this is not enough:

```text
StudentID + CourseCode
```

A better candidate is:

```text
StudentID + CourseCode + Semester
```
---
# Constraints

Our model should reject invalid states.

For example:

* duplicate Student IDs
* duplicate Course Codes
* enrollment for a missing student
* enrollment for a missing course
* invalid grade
---
# Break the model

What is wrong here?

```text
STUDENT

1042  Alice
1042  Bob
```
---
# Break the model

What is wrong here?

```text
ENROLLMENT

1042  DB999  2026W  A
```

Assume that `DB999` does not exist.
---
# Break the model

What is wrong here?

```text
1042  DB101  2026W  B
1042  DB101  2026W  A
```
---
# Break the model

What is wrong here?

```text
1042  DB101  2026W  Excellent
```

Assume:

```text
Grade = {A, B, C, D, E, F}
```
---
# Why constraints matter

Structure tells us what can be represented.

Constraints tell us:

> Which representations are valid?
---
# Same world as a graph

Now represent the same information differently.

```text
(Alice) ---> (Database Systems)
```

But what should the connection mean?
---
# A graph model

```text
(:Student)
    |
    | ENROLLED_IN
    v
(:Course)
```

Now the relationship itself has meaning.
---
# Relationship properties

The relationship may contain:

```text
semester = 2026W
grade    = B
```

So we can represent:

```text
Alice -[ENROLLED_IN]-> DB101
```
---
# Same information

Relational:

```text
ENROLLMENT(
  1042,
  DB101,
  2026W,
  B
)
```

---
# Same information
## contd.

Graph:

```text
(Alice)-[
  ENROLLED_IN
  semester: 2026W
  grade: B
]->(DB101)
```
---
# Compare

Where is Enrollment in the relational model?

Where is Enrollment in the graph model?

What becomes explicit?

What becomes implicit?
---
# Compare
## contd.

Which model makes this easier to see?

```text
Alice is enrolled in DB101
```

Which model makes tabular data easier to inspect?
---
# Same world. Different model.

The university did not change.

The students did not change.

The courses did not change.

Our **representation** changed.
---
# One question, two languages

Suppose we ask:

> Which courses does Alice attend?

In SQL:
---
# SQL preview

```sql
SELECT c.Title
FROM STUDENT s
JOIN ENROLLMENT e
  ON e.StudentID = s.StudentID
JOIN COURSE c
  ON c.CourseCode = e.CourseCode
WHERE s.Name = 'Alice';
```

Do not worry about the syntax yet.

What structure can you recognize?
---
# Cypher preview

The same question in Cypher:

```cypher
MATCH (:Student {name: 'Alice'})
      -[:ENROLLED_IN]->
      (c:Course)
RETURN c.title;
```

What structure can you recognize here?
---
# Compare the questions

SQL describes the path through:

* tables
* matching values
* joins

---
# Compare the questions
## contd.
Cypher describes the path through:

* nodes
* relationships
* patterns

Same question.

Different model.
---
# Your project will do this

A practical domain will eventually be modelled as:

```text
relational database
```

and:

```text
graph database
```

The important part is not choosing a favourite.

It is understanding the consequences of each model.
---
# Think of a domain

Choose something you understand.

For example:

* library
* hotel
* music festival
* football club
* online shop
* cinema
* public transport
---
# A good project domain

It should contain:

* several kinds of things
* meaningful relationships
* some constraints
* questions worth asking
* enough complexity to compare models

But not an entire universe.
---
# Preparation

For your candidate domain, prepare:

1. 5–10 sentences describing it
2. at least 3 kinds of things
3. at least 2 relationships
4. at least 3 rules or constraints
5. 3 questions the database should answer
---
# Before you leave

Can you explain the difference between:

* world and representation
* schema and instance
* structure and constraint
* relational and graph representation

If yes, today worked.
---
# Q&A

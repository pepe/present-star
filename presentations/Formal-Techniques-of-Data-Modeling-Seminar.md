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
===
title: UML — One System, Several Views
author: Josef Pospíšil
date: 2026-10-20
---
# UML: One System, Several Views

EIED5E · Formal Techniques of Data Modelling

Seminar · Student, Course and Enrollment

---
# Today's work

- Choose a UML diagram for a modelling question.
- Build a class model with meaningful multiplicities.
- Check that structure and behaviour agree.

---
# Our shared system

Students request places in course offerings.

A registrar approves or rejects requests.

Students can view their requests and cancel confirmed enrollments.

---
# Rules for this exercise

- Each offering belongs to one course and has a capacity.
- Each enrollment concerns one student and one offering.
- A student has at most one enrollment record per offering.

---
# Several questions, several views

| Question | Diagram |
|---|---|
| Who wants which result? | Use case |
| Which concepts and relationships exist? | Class |
| Which steps and choices occur? | Activity |
| Which lifecycle changes are allowed? | State machine |

---
# Several questions, several views
## contd.

| Question | Diagram |
|---|---|
| Who sends which messages? | Sequence |
| Which modules depend on which others? | Component |
| Where do artifacts run? | Deployment |
| How do we customise UML vocabulary? | Profile |

---
# Use cases: actor goals 🏛️

An actor represents an external role interacting with the system.

A use case describes behaviour that delivers an observable result of value.

Name a goal such as **Request enrollment**.

---
# The system boundary

Our boundary is the **Enrollment System**.

Student and Registrar are roles outside that boundary.

One person may play several actor roles.

---
# An enrollment use-case view

![Use-case diagram with Student and Registrar actors outside the Enrollment System](/img/ftdm-seminar/uml/use-case.png)

---
# Actor or internal detail? 🧪

Which belong in this use-case diagram?

**Student · Save database row · Registrar · Request enrollment**

Explain the purpose of each choice.

---
# Actor or internal detail?
## contd.

Student and Registrar are actors.

Request enrollment is an actor goal.

Saving a database row is an internal implementation step in this scenario.

---
# A diagram needs a scenario

**Goal:** request enrollment in an offering.

**Main flow:** select offering, submit request, receive pending status.

**Alternative:** an existing record prevents a duplicate request.

---
# Class diagrams: domain structure 🏛️

A class describes a type of object in our model.

Attributes describe properties of its instances.

Associations describe possible links between instances.

---
# Class and instance

**Student** is a class.

**Student S17, named Ada**, is one instance.

Our class model describes many possible student populations.

---
# Class notation

The upper compartment contains the class name.

Attributes use `name: Type`, such as `studentId: String`.

Operations can occupy another compartment when the modelling purpose needs them.

---
# Associations

An Enrollment links a Student to a CourseOffering.

Association lines describe structural relationships.

Their positions on the page do not imply a workflow.

---
# Multiplicity 🏛️

`1` means exactly one. `0..1` means optional, at most one.

`0..*` means zero or more. `1..*` means one or more.

Read an end's multiplicity as the number of instances at that end for one at the opposite end.

---
# Reading the ends

![Student 1 associated with Enrollment 0..*, with both readings written below](/img/ftdm-seminar/uml/multiplicity.png)

---
# A multiplicity prediction 🧪

An Enrollment always belongs to one Student.

A Student may exist before submitting any request.

Which multiplicity belongs at each end?

---
# A multiplicity prediction
## contd.

Place `1` at the Student end.

Place `0..*` at the Enrollment end.

Using `1..*` at Enrollment would exclude students with no requests.

---
# Course and CourseOffering

Course represents the subject, such as Formal Modelling.

CourseOffering represents a particular delivery in a term.

The same Course may have several offerings, including in the same term.

---
# Enrollment has its own information

`enrollmentId: String` identifies a request record.

`status: EnrollmentStatus` records its lifecycle condition.

For this exercise: pending, confirmed, rejected or cancelled.

---
# Constraints beyond multiplicity

The Student–CourseOffering pair is unique across Enrollment records.

The number of confirmed enrollments cannot exceed the offering's capacity.

Capacity is non-negative. Approval also requires an active student.

---
# Building the model 🧪

In pairs, draw Student, Course, CourseOffering and Enrollment.

Add identifying attributes, associations and multiplicities.

Write the uniqueness and capacity constraints beside the diagram. **10 minutes.**

---
# A worked class model

![Four-class enrollment model with Student, Enrollment, CourseOffering and Course](/img/ftdm-seminar/uml/class-model.png)

---
# Testing with instances 🧪

| Situation | Valid under our rules? |
|---|---|
| Student S17 has no enrollments | ? |
| One Enrollment links two Students | ? |
| S17 has records for two different offerings | ? |
| S17 has two records for the same offering | ? |

---
# Testing with instances
## contd.

Yes: a student may have zero enrollments.

No: each Enrollment links exactly one Student.

Yes for different offerings. No for duplicate records in one offering.

---
# What multiplicity leaves open

An offering has capacity 20 and 21 confirmed enrollments.

The `0..*` multiplicity alone allows those links.

The capacity constraint rules out this instance.

---
# Generalisation and ownership

Generalisation describes an “is a” relationship, with a hollow triangle pointing to the general class.

Composition adds strong whole–part ownership, marked by a filled diamond at the whole.

Our enrollment links need ordinary associations. They assert neither relationship.

---
# Activity diagrams: a workflow

Actions describe work. Arrows show flow.

A decision selects a path using guards such as `[eligible]` and `[else]`.

A merge reunites alternatives. A join synchronises concurrent flows.

---
# A request-assessment workflow

![Activity diagram showing request submission, assessment and eligible or else branches](/img/ftdm-seminar/uml/activity.png)

---
# State machines: one lifecycle

Focus on one Enrollment and the conditions it can occupy.

A transition label can use `trigger [guard] / effect`.

**pending** is a state. **approve** is an event requesting a change.

---
# The Enrollment lifecycle

![State machine with pending, confirmed, rejected and cancelled states](/img/ftdm-seminar/uml/state-machine.png)

---
# Consistency check 🧪

A teammate's activity diagram confirms a request when the student is inactive.

The state machine permits approval only when `[eligible]` holds.

Can both describe our agreed system correctly?

---
# Consistency check
## contd.

They disagree with the rule defining eligibility.

The approval path must require an active student and a place available.

The diagrams express different views of the same rules.

---
# Peer review 🧪

Exchange class models with another pair.

Read each multiplicity aloud and propose one invalid instance.

Check whether the model or a written constraint excludes it. **4 minutes.**

---
# Today's submission

- One class diagram with multiplicities.
- Two explicit constraints and one invalid example.
- One sentence connecting an Enrollment state to a workflow action.

---
# Sequence diagrams: an interaction

Lifelines represent participants in an interaction.

Messages show communication between participants.

Read downward for ordering, without treating vertical distance as elapsed time.

---
# Submitting a request

![Sequence diagram showing Student, EnrollmentUI and EnrollmentService messages](/img/ftdm-seminar/uml/sequence.png)

---
# One scenario, a larger lifecycle

This interaction ends when submission returns a pending request.

Registrar assessment happens later in a separate interaction.

The sequence and state diagrams must agree about the resulting status.

---
# Component diagrams: software modules

Components encapsulate modular parts of a system.

They can expose provided interfaces and require interfaces from others.

A dependency arrow points from a client towards its supplier.

---
# An illustrative component view

![Enrollment UI depends on Enrollment Service, which depends on Student Registry](/img/ftdm-seminar/uml/component.png)

---
# Deployment diagrams: runtime placement

Nodes describe devices or execution environments.

Artifacts describe deployable pieces of software.

Communication paths connect nodes.

---
# An illustrative deployment view

![Client device with browser connected over HTTPS to application server with service artifact](/img/ftdm-seminar/uml/deployment.png)

---
# Profiles: UML for a domain

A profile defines stereotypes extending selected UML metaclasses.

Stereotype properties and constraints add domain-specific meaning.

Profile extensions must respect the underlying UML semantics.

---
# An illustrative profile

![UniversityModel profile defines AuditedRecord stereotype extending the Class metaclass](/img/ftdm-seminar/uml/profile.png)

---
# Which diagram would you choose? 🧪

- Which requests may a Registrar assess?
- Which messages submit one request?
- Which machine hosts the service artifact?
- How many Enrollments can one Student have?

---
# Which diagram would you choose?
## contd.

Use-case view for actor participation, with text for assessment conditions.

Sequence for messages. Deployment for runtime placement.

Class diagram for association multiplicity.

---
# Common modelling traps

A class name and an actor role can share a word while serving different purposes.

Multiplicity does not express every business constraint.

Changing a status does not necessarily delete an object or its history.

---
# What should stay consistent?

The same domain terms and identity assumptions.

The same conditions for approval and cancellation.

The same meaning of pending, confirmed, rejected and cancelled.

---
# Study materials: behaviour

[Use-case diagrams](https://www.visual-paradigm.com/guide/uml-unified-modeling-language/what-is-use-case-diagram/)

[Activity diagrams](https://www.visual-paradigm.com/guide/uml-unified-modeling-language/what-is-activity-diagram/) · [Sequence diagrams](https://www.visual-paradigm.com/guide/uml-unified-modeling-language/what-is-sequence-diagram/)

[State machine diagrams](https://www.visual-paradigm.com/guide/uml-unified-modeling-language/what-is-state-machine-diagram/)

---
# Study materials: structure

[Class diagrams](https://www.visual-paradigm.com/guide/uml-unified-modeling-language/uml-class-diagram-tutorial/) · [Component diagrams](https://www.visual-paradigm.com/guide/uml-unified-modeling-language/what-is-component-diagram/)

[Deployment diagrams](https://www.visual-paradigm.com/guide/uml-unified-modeling-language/what-is-deployment-diagram/) · [Profile diagrams](https://www.visual-paradigm.com/guide/uml-unified-modeling-language/what-is-profile-diagram/)

[OMG UML specification](https://www.omg.org/spec/UML/2.5.1/About-UML)

---
# Questions 💬

Which modelling question does your diagram answer?

Which important question does it leave to another view?

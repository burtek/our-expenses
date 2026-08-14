Create a complete Flutter mobile application for tracking and settling shared expenses.

The application should be **local-first**, require no backend, and persist all data locally on the device.

## Goals

The app is intended primarily for situations such as trips, holidays, family gatherings, or other temporary groups where multiple people pay for expenses and expenses need to be fairly settled afterwards.

The most important requirement is that the expense calculation model must support:

* multiple people paying for a single expense,
* multiple beneficiaries,
* different ways of splitting an expense,
* and grouping people into **settlement groups/units** so that several people can be treated as one party when calculating who owes whom.

---

# Technology

Use:

* Flutter
* Dart
* Material 3
* Local persistent storage
* English and Polish localization
* GitHub Actions for CI/CD

Prefer a clean, maintainable architecture with clear separation between:

* domain/business logic,
* persistence,
* application state,
* and UI.

Keep the domain calculation logic independent from Flutter widgets so it can be thoroughly unit-tested.

Choose appropriate Flutter packages when useful, but avoid unnecessary dependencies.

---

# Localization

The application must support:

* English (`en`)
* Polish (`pl`)

Use Flutter's standard localization mechanism (`flutter_localizations` / ARB files or an equivalent maintainable approach).

Do not hardcode user-facing strings in widgets.

The default language should follow the device language when supported, with English as the fallback.

---

# Local-first persistence

The application must work completely offline.

All user data must be persisted locally so that:

* closing the application does not lose data,
* restarting the application restores the previous state,
* no internet connection is required,
* there is no backend or account system.

Persist at least:

* trips/groups,
* people,
* settlement groups,
* expenses,
* payments,
* expense splits.

Use a suitable local persistence solution for Flutter. Keep persistence behind an abstraction so the domain layer does not depend directly on the database implementation.

---

# Core concept: Trips

Expenses must be organized into completely independent **Trips**.

A Trip represents an isolated expense-settlement context, for example:

* "Italy 2026"
* "Weekend in Prague"
* "Family Christmas"
* "Camping Trip"

Data from one trip must never affect calculations in another trip.

A trip contains:

* name,
* optional description,
* participants,
* settlement groups,
* expenses.

Users should be able to:

* create a trip,
* rename it,
* delete it,
* open it,
* add/remove participants,
* add/edit/delete expenses.

When deleting a trip, require confirmation.

---

# Participants

Within a trip, users can add people.

A person should have at least:

* unique ID,
* display name.

A person can participate in multiple trips, but their participation in each trip is independent.

For example, "Alice" in Trip A and "Alice" in Trip B must not cause expenses to cross between trips.

---

# Settlement groups

A key feature is the ability to group several participants into a single **settlement unit**.

This is NOT the same thing as grouping expenses.

A settlement group defines people who should settle their combined balance together.

Example:

Participants:

* A
* B
* C
* D
* E
* F

Settlement groups:

* A + B → "A & B"
* C + D + E → "C & D & E"
* F → "F"

Suppose C pays for €60 of coffee for:

* C
* D
* A
* F

The expense itself still belongs to the individual people who consumed it.

However, when calculating the final settlement, the balances of A and B should be combined, and the balances of C, D and E should be combined.

The final result should therefore be able to say something like:

> A & B owe C & D & E €X

rather than producing separate transactions between every individual member.

Important:

* Settlement groups affect **final settlement aggregation only**.
* They must NOT change who benefited from an individual expense.
* Individual expense records must always retain the actual payer(s) and beneficiary/beneficiaries.
* A person can belong to at most one settlement group within a trip.
* A settlement group can contain one or more people.
* A person not explicitly grouped is effectively their own settlement group.

Allow creating, editing and deleting settlement groups.

The UI should make the distinction between:

1. individual participants,
2. settlement groups,
3. expense beneficiaries

very clear.

---

# Expenses

Each expense must contain at least:

* unique ID,
* description/title,
* date/time,
* one or more payers,
* one or more beneficiaries,
* total amount,
* currency.

For every payer, the user must be able to specify the **exact amount they paid**.

Example:

Dinner = €100

Paid by:

* Alice: €60
* Bob: €40

The sum of payer amounts must equal the expense total.

---

# Beneficiaries / expense splitting

An expense can have one or more beneficiaries.

The user must be able to choose how the total expense is distributed between beneficiaries.

Support these split modes:

### 1. Equally

The amount is divided equally between all selected beneficiaries.

Example:

€90 for A, B and C

Result:

* A: €30
* B: €30
* C: €30

### 2. By shares

Each beneficiary receives a configurable number of shares.

Example:

€100

* A: 1 share
* B: 1 share
* C: 2 shares

Result:

* A: €25
* B: €25
* C: €50

### 3. Exact amounts

The user specifies the exact amount assigned to every beneficiary.

Example:

€100

* A: €20
* B: €30
* C: €50

The application must validate that the beneficiary amounts add up exactly to the expense total.

Use integer minor currency units internally (for example cents/grosze), not floating-point numbers, to avoid rounding errors.

---

# Multiple payers + multiple beneficiaries

The calculation engine must support arbitrary combinations of multiple payers and beneficiaries.

For example:

Total: €120

Payers:

* A: €80
* B: €40

Beneficiaries:

* C: €60
* D: €30
* E: €30

The expense creates the appropriate balances between what each person paid and what they consumed.

Do not simplify the data model by assuming that every expense has exactly one payer or one beneficiary.

---

# Settlement calculation

The application must calculate the net balance for every participant.

For each participant:

**balance = amount paid - amount owed for consumed expenses**

Positive balance:

* the person should receive money.

Negative balance:

* the person owes money.

Zero:

* the person is settled.

Then aggregate individual balances according to settlement groups.

For example:

Individual balances:

* A: -€30
* B: -€20
* C: +€25
* D: +€15
* E: +€10
* F: €0

Settlement groups:

* A + B
* C + D + E
* F

Consolidated balances:

* A & B: -€50
* C & D & E: +€50
* F: €0

The UI should show these consolidated balances prominently.

---

# Who owes whom

From the consolidated balances, calculate a simplified set of settlement transactions.

Example:

* A & B owe C & D & E €50

The application should minimize the number of required transactions where reasonably possible.

The settlement algorithm must:

* never create money,
* never lose money,
* preserve the total balance,
* correctly handle positive/negative/zero balances,
* work with arbitrary numbers of participants and settlement groups.

Show the final result in a clear human-readable form.

For example:

> A & B → C & D & E: €50

If multiple transactions are necessary, display each one.

The algorithm should operate on integer minor currency units.

---

# Expense details

For every expense, show:

* description,
* date,
* total,
* who paid,
* how much each payer paid,
* who benefited,
* how much each beneficiary was assigned,
* split method.

Allow editing and deleting expenses.

When deleting an expense, require confirmation.

---

# Trip overview

The trip screen should provide a useful summary.

Show:

### Total expenses

Total amount spent during the trip.

### Participants

List of people participating in the trip.

### Individual balances

Show how much each person is currently owed/owes before settlement-group aggregation.

### Settlement groups

Show the consolidated balance for every settlement group.

### Final settlement

Show who should pay whom and how much.

The final settlement should be the most prominent part of the overview.

---

# UX

Design the application primarily for mobile phones.

Use a clean, simple Material 3 interface.

The main navigation should make it easy to access:

* Trips
* Trip details
* Expenses
* Settlement summary
* Participants / settlement groups

Adding an expense should be fast and require as few steps as reasonably possible.

Use appropriate controls for:

* selecting people,
* entering monetary values,
* choosing split mode,
* configuring shares,
* entering exact amounts.

Validate all user input.

Examples of invalid states:

* payer amounts do not equal total,
* beneficiary amounts do not equal total,
* no payer selected,
* no beneficiary selected,
* negative amounts,
* zero/invalid shares.

Display useful validation messages.

---

# Currency

For the first version, each trip should use a single currency.

When creating a trip, allow selecting the currency.

At minimum support:

* EUR
* PLN
* USD
* GBP
* CZK

The currency should be stored as part of the trip.

Money calculations must always use integer minor units.

Display amounts using appropriate currency formatting.

Do not attempt currency conversion.

---

# Domain model

Design a proper domain model.

At minimum, consider entities/value objects equivalent to:

* Trip
* Person
* SettlementGroup
* Expense
* ExpensePayer
* ExpenseBeneficiary
* Money
* SettlementTransaction

Keep the calculation engine deterministic and independent from persistence/UI.

It should be possible to pass a set of expenses and settlement groups into the calculation engine and obtain:

* individual balances,
* consolidated group balances,
* final settlement transactions.

---

# Testing

Write comprehensive unit tests for the domain/business logic.

Especially test:

* one payer / one beneficiary,
* one payer / multiple beneficiaries,
* multiple payers / one beneficiary,
* multiple payers / multiple beneficiaries,
* equal split,
* share-based split,
* exact-amount split,
* rounding cases,
* zero balances,
* multiple settlement groups,
* people without settlement groups,
* mixed grouped and ungrouped participants,
* expenses involving people from different settlement groups,
* several expenses,
* multiple currencies/trips being isolated,
* settlement minimization,
* cases where one settlement group owes several others,
* cases where several settlement groups owe one group,
* cases where balances cancel out exactly.

Use property/invariant-style tests where practical.

Important invariants:

1. Sum of all individual balances must always equal zero.
2. Sum of all consolidated settlement-group balances must always equal zero.
3. Sum of all generated settlement transactions must equal zero.
4. For every expense, sum of payer amounts must equal the total.
5. For every expense, sum of beneficiary amounts must equal the total.

---

# CI/CD

Create a GitHub Actions workflow.

On every push and pull request:

1. Check out the repository.
2. Set up Flutter.
3. Install dependencies.
4. Run formatting checks.
5. Run static analysis.
6. Run all unit/widget tests.
7. Build the Android APK.

The workflow should fail if:

* formatting is invalid,
* analysis reports errors,
* tests fail,
* APK build fails.

For pushes to the main branch, also produce the APK as a GitHub Actions artifact that can be downloaded and installed on an Android phone.

Prefer producing a release APK suitable for manual installation.

The artifact should have a clear name such as:

`expense-settler-android.apk`

Do not require publishing to Google Play.

---

# Code quality

Follow modern Flutter/Dart best practices.

Requirements:

* null safety,
* strong typing,
* meaningful names,
* small and testable components,
* no business logic inside UI widgets where it can reasonably be avoided,
* no duplicated calculation logic,
* proper error handling,
* proper localization,
* clean separation of concerns.

Avoid overengineering. This is a relatively small offline-first application, so prefer a simple architecture that remains easy to understand and maintain.

---

# README

Create a README explaining:

* what the application does,
* the core concepts,
* how settlement groups work,
* how expenses are calculated,
* how to run the application locally,
* how to run tests,
* how to build the Android APK,
* how the GitHub Actions workflow works.

Include a concrete example demonstrating the A+B / C+D+E / F scenario described above.

---

# Deliverable

Implement the application, not just a prototype or mockup.

The result should be a runnable Flutter application with:

* functional UI,
* local persistence,
* complete expense calculation engine,
* settlement groups,
* final settlement calculation,
* English and Polish localization,
* unit tests,
* GitHub Actions CI/CD,
* downloadable Android APK artifact.

Prioritize correctness of the financial calculation engine over visual polish.
The calculation engine must be extensively tested before considering the implementation complete.

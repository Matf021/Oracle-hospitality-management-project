# Oracle Hospitality Management System

A relational database system for managing hotel reservations, room assignments, guest stays, folios, payments, and restaurant charges. The project uses Oracle SQL and PL/SQL to model hospitality operations, automate multi-step workflows, enforce business rules, and maintain reliable transactional data.

## Overview

This project was designed around realistic hotel and restaurant operations. It demonstrates how a relational database and PL/SQL business layer can coordinate workflows involving guests, reservations, rooms, stays, charges, payments, and checkout.

The system is being developed incrementally, with each management area implemented as a modular PL/SQL package and verified through automated test scripts.

The system includes:

- guest record management
- multi-room hotel reservations
- room assignment and availability validation
- guest check-in and stay creation
- folio creation and charge tracking
- payment and balance management
- guest checkout workflows
- restaurant charges posted to hotel rooms
- automated business-rule validation
- PL/SQL test suites for successful and rejected operations

## Project Goals

The project focuses on:

- designing a normalized relational database for hospitality operations
- implementing reusable business logic with PL/SQL packages
- maintaining data integrity across multi-step transactions
- handling invalid operations with application-specific Oracle errors
- testing both successful workflows and expected failure conditions
- creating a reproducible Oracle development environment with Docker

## Database Design

The database models the relationships between:

- guests
- reservations
- rooms
- reservation room assignments
- stays
- folios
- folio charges
- payments
- restaurant orders

A reservation can include multiple rooms, allowing one guest to manage a booking for a larger group. Room assignments are validated against capacity, availability, maintenance status, and the number of guests included in the reservation.

Guest records are retained for historical consistency. Instead of deleting guests referenced by previous transactions, the system supports anonymization while preserving operational records.

# Implemented Modules
# Reservation Management

The reservation management package handles guest registration, reservation creation, and room assignment.

It validates:

- guest existence and anonymization status
- reservation date ranges
- number of guests
- room existence
- room occupancy limits
- duplicate room assignments
- overlapping reservations
- reservation capacity
- room maintenance status

# Stay and Folio Management

The stay and folio package manages the transition from a confirmed reservation to an active hotel stay.

It supports:

- validating reservations before check-in
- preventing duplicate check-ins
- creating a stay from a booked reservation
- opening a folio automatically
- adding room charges to the folio
- preventing duplicate room charges
- calculating the outstanding folio balance
- preventing checkout when an unpaid balance remains
- completing checkout after the folio has been paid

# Payment Management

The payment module manages payments applied to guest folios.

Its intended responsibilities include:

- recording folio payments
- validating payment amounts
- preventing overpayments
- updating outstanding balances
- supporting paid checkout
- retaining payment history

# Restaurant Management

The restaurant module is designed to integrate hotel and restaurant operations.

Planned functionality includes:

- creating restaurant orders
- adding menu items to orders
- calculating order totals
- posting restaurant charges to a guest’s room
- linking restaurant charges to the appropriate folio
- supporting additional payment methods in future versions

# Core Workflow
1. A guest record is created
2. A reservation is created for the guest
3. One or more rooms are assigned to the reservation
4. Room availability, capacity, and maintenance status are validated
5. The guest checks in
6. A stay and an associated folio are created
7. Room and additional charges are posted to the folio
8. Payments are applied against the outstanding balance
9. Checkout is completed once the folio balance reaches zero

# Business Rules

The PL/SQL business layer prevents operations such as:

- creating a reservation for a nonexistent or anonymized guest
- using an invalid arrival and departure date range
- creating a reservation with zero guests
- assigning a nonexistent room
- exceeding a room’s occupancy limit
- assigning the same room more than once
- creating overlapping reservations for the same room
- assigning a room that is under maintenance
- checking in a reservation without assigned rooms
- checking in the same reservation more than once
- adding duplicate room charges
- checking out with an unpaid balance
- paying more than the outstanding folio balance

Invalid operations are rejected with descriptive application-specific Oracle error codes.

# Testing

The project includes automated PL/SQL test suites for each management package.

Tests cover:

- valid end-to-end workflows
- invalid foreign-key references
- reservation validation
- room availability and occupancy rules
- duplicate operations
- check-in requirements
- folio charge validation
- unpaid checkout prevention
- successful paid checkout

Each test reports a clear pass or failure result and verifies that rejected operations return the expected Oracle error code.

# Tech Stack
- Oracle Database Free
- SQL
- PL/SQL
- Docker
- Git and GitHub

# Development Environment

Oracle Database runs inside a Docker container, providing an isolated and reproducible local development environment. Database scripts are executed through an Oracle database connection configured for the project.

# Current Status

Completed:

- database schema and relationships
- reservation management package
- reservation management tests
- stay and folio management package
- stay and folio management tests
- business-rule validation and custom error handling

In progress:

- payment management
- restaurant order management
- complete end-to-end hospitality workflow testing

# Future Improvements

- payment refunds and reversals
- split restaurant payments
- additional restaurant payment methods
- room-rate and tax calculations
- reservation cancellation workflows
- reporting views for occupancy, revenue, and guest activity
- role-based database permissions
- audit logging for sensitive operations
- a backend API or web interface connected to the database
  
# Notes

This is a portfolio project created to demonstrate relational database design, Oracle SQL, PL/SQL package development, transactional business logic, automated database testing, and containerized database development.


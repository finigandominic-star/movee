# GEMINI.md

This file provides guidance to Antigravity and AI coding assistants when working with code in this repository.

See [CLAUDE.md](file:///home/domfi/code/finigandominic-star/movee/CLAUDE.md) for full project documentation, models, routes, test commands, and UI conventions.

## Quick Summary

- **Framework**: Rails 8.1.4, Ruby 3.3.5, PostgreSQL.
- **Frontend**: Bootstrap 5.3, Font Awesome 6, Simple Form, Sprockets + SassC.
- **Authentication**: Devise (`User` model with `user_name` and `company`).
- **Core Entities**:
  - `User`: Real estate agents/brokers.
  - `Property`: Properties listed by users.
  - `InvolvedParty`: Buyers/sellers involved in property chains.
  - `Chain`: Transaction chains tracking progress across multiple properties.
  - `Transaction`: Join of property, chain, and client party.
- **Testing**: `bin/rails test` (Minitest suite covering models, controllers, and Devise registration).
- **Seeds**: `bin/rails db:seed` (Idempotent seed data with 5 users, 3 chains, 25 involved parties, 20 properties, 20 transactions).

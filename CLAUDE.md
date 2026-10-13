# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) and AI assistants when working with code in this repository.

## Overview

Rails 8.1 app (PostgreSQL, Hotwire/Turbo + Stimulus via importmap) generated from the Le Wagon rails-templates. It models UK-style property sales chains: real estate agents/users list properties, and properties move through transactions that belong to a chain alongside buyer/seller involved parties.

Front-end stack follows the Le Wagon template: Sprockets + SassC with Bootstrap 5.3, Font Awesome 6, and Simple Form (not Propshaft/Tailwind). Authentication is handled via Devise (`devise_for :users`) with custom profile fields (`user_name` and `company`). Env vars are loaded from `.env` via dotenv-rails in dev/test.

## Commands

```bash
bin/setup                 # install gems, prepare DB, start server (add --skip-server to skip)
bin/dev                   # run the server (plain `rails server`, port 3000)
bin/rails db:migrate      # run database migrations and regenerate db/schema.rb
bin/rails db:seed         # seed sample users, chains, involved parties, properties, and transactions
bin/rails test            # run entire Minitest test suite (models, controllers, integration)
bin/rails test test/models/property_test.rb       # single test file
bin/rails test test/models/property_test.rb:12    # single test by line
bin/rubocop               # lint (config in .rubocop.yml; test/, db/, config/, bin/ are excluded)
bin/brakeman              # security scan
bin/ci                    # full local CI pipeline defined in config/ci.rb
```

## Domain Model

See `db/schema.rb` for exact schema columns and indexes:

- **`User`** (`devise :database_authenticatable, :registerable, ...`):
  - Attributes: `email`, `user_name`, `company`, `encrypted_password`.
  - Associations: `has_many :properties, dependent: :destroy`.
  - Validations: `user_name` presence, password complexity (at least 8 chars, letters and numbers) on creation/password updates.
  - Strong Parameters configured in `ApplicationController` (`:user_name`, `:company`).

- **`InvolvedParty`**:
  - Attributes: `first_name`, `last_name`, `email`, `phone`, `contact_info`, `seller` (bool), `buyer` (bool).
  - Associations: `has_many :properties, dependent: :nullify`, `has_many :transactions, dependent: :nullify`, `has_many :chains, through: :transactions`.
  - Helper methods: `full_name`, `roles_label` ("Seller", "Buyer", "Seller / Buyer", "Contact").

- **`Property`**:
  - Attributes: `house_number`, `street`, `second_line_of_address`, `city`, `post_code`, `photos`, `sold` (bool), `user_id`, `involved_party_id`.
  - Associations: `belongs_to :user`, `belongs_to :involved_party, optional: true`, `has_many :transactions, dependent: :destroy`, `has_many :chains, through: :transactions`.
  - Helper methods: `full_address` (proper UK format), `short_address`.

- **`Chain`**:
  - Attributes: `active` (bool).
  - Associations: `has_many :transactions, dependent: :destroy`, `has_many :properties, through: :transactions`, `has_many :involved_parties, through: :transactions`.

- **`Transaction`**:
  - Attributes: `property_id`, `chain_id`, `involved_party_id`, `completed` (bool).
  - Associations: `belongs_to :property`, `belongs_to :chain`, `belongs_to :involved_party, optional: true`.
  - Scopes: `Transaction.completed`, `Transaction.pending`.
  - Helper methods: `status_label`, `status_badge_class`.

## Routes & Controllers

Standard RESTful resource routing defined in `config/routes.rb`:

- **`properties`** (`PropertiesController`):
  - Standard CRUD (`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`).
  - Member route: `DELETE /properties/:id/remove_involved_party`.

- **`transactions`** (`TransactionsController`):
  - Standard CRUD (`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`).
  - Supports query parameter pre-population on `new` (`?property_id=...&chain_id=...`).
  - Member route: `DELETE /transactions/:id/remove_involved_party`.

- **`involved_parties`** (`InvolvedPartiesController`):
  - Standard CRUD (`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`).
  - Member routes for assignment workflows:
    - `POST /involved_parties/:id/assign_property`
    - `DELETE /involved_parties/:id/unassign_property/:property_id`
    - `POST /involved_parties/:id/assign_transaction`
    - `DELETE /involved_parties/:id/unassign_transaction/:transaction_id`

- **`users`** (Devise):
  - Standard Devise routes (`new_user_session`, `new_user_registration`, `edit_user_registration`, etc.).

## UI & Styling Conventions

- All views follow **Bootstrap 5.3** conventions with **Font Awesome 6** icons.
- Forms use `simple_form_for` with `.form-control` and `.btn` classes.
- Listing pages (e.g. `properties/index`) support grid card view and responsive table views.
- Turbo confirms and method overrides (`data: { turbo_confirm: "..." }`) are used for destructive actions.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Rails 8.1 app (PostgreSQL, Hotwire/Turbo + Stimulus via importmap) generated from the Le Wagon rails-templates. It models UK-style property sales chains: users list properties, and properties move through transactions that belong to a chain. Early-stage project — controllers and routes are still being built out.

Front-end stack follows the Le Wagon template: Sprockets + SassC with Bootstrap 5.3, Font Awesome, and Simple Form (not Propshaft/Tailwind). Authentication is Devise (`devise_for :users`). Env vars are loaded from `.env` via dotenv-rails in dev/test.

## Commands

```bash
bin/setup                 # install gems, prepare DB, start server (add --skip-server to skip)
bin/dev                   # run the server (plain `rails server`, no Procfile)
bin/rails db:migrate      # regenerates db/schema.rb
bin/rails test            # all tests (Minitest)
bin/rails test test/models/property_test.rb       # single file
bin/rails test test/models/property_test.rb:12    # single test by line
bin/rubocop               # lint (config in .rubocop.yml; test/, db/, config/, bin/ are excluded; max line length 120)
bin/brakeman              # security scan
bin/ci                    # full local CI pipeline defined in config/ci.rb (setup, rubocop, audits, brakeman, tests, seed replant)
```

## Domain model

See `db/schema.rb` for columns; the relationships are:

- `User` (Devise) `has_many :properties`.
- `InvolvedParty` — a buyer/seller contact (`buyer`/`seller` booleans). Has many properties and transactions, and chains through transactions.
- `Property` — address fields + `sold`; belongs to a `User` and an `InvolvedParty`.
- `Chain` — a property chain (`active` flag); has many transactions.
- `Transaction` — join of `InvolvedParty`, `Chain`, and `Property`, with a `completed` flag.

## Known inconsistencies (work in progress)

Check these before assuming code works — the models, schema and routes are out of sync:

- `Property` declares `belongs_to :chain`, but the `properties` table has no `chain_id` column (properties link to chains only via `transactions`).
- `User` validates `user_name`, but there is no `user_name` column. Its `password` presence/format validation will also run on every save (e.g. Devise updates that don't change the password).
- `config/routes.rb` contains `resources :properties` plus an invalid line `property :resources, except (:index)` and a TODO for transaction routes — the file currently won't load.
- Controllers are singular (`PropertyController`, `TransactionController`) and empty, whereas `resources :properties` routes to `PropertiesController`. Rails convention expects plural controller names.
- `app/views` only has `pages/` and `layouts/`; no property/transaction views exist yet.

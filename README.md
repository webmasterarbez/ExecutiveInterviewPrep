# Build New

Rails 8 + React 19 + PostgreSQL app using Inertia.js, TypeScript, Tailwind CSS 4, and shadcn/ui.

## Requirements

- Ruby 3.2.0
- Node.js (for Vite)
- PostgreSQL 14+

## Setup

Ensure PostgreSQL is running locally, then:

```bash
bin/setup
```

This installs gems, creates and migrates the development/test databases, and starts the dev server.

If your PostgreSQL user/password differs from the defaults (uses your OS user, no password), set:

```bash
export DATABASE_USERNAME=your_pg_user
export DATABASE_PASSWORD=your_pg_password
export DATABASE_HOST=localhost   # optional, defaults to localhost
```

## Commands

```bash
bin/dev                # Start dev server (Rails on :3000 + Vite on :3036)
bin/rails test         # Run unit/integration tests (Minitest)
bin/rails test:system  # System tests (Capybara + headless Chrome)
npm run check          # TypeScript type checking
bin/rubocop            # Ruby linting
bin/brakeman           # Security scanning
```

## Services

Background jobs (Solid Queue), caching (Solid Cache), and WebSockets (Solid Cable) are all database-backed and share the single primary PostgreSQL database — no Redis, no separate databases.

## Deployment

Production expects a `DATABASE_URL` environment variable pointing at the primary PostgreSQL database. The Dockerfile installs `postgresql-client` and `libpq-dev`.

# PaperTrade

PaperTrade is a small Ruby on Rails application that lets you simulate trading a handful of liquid U.S. equities from a clean dashboard. The goal is to help you log buys and sells, keep a running view of your portfolio, and see how your paper portfolio moves against historical market data without risking real capital.

## Core features

- **Authenticated experience:** Users sign up via Devise, start with a $100,000 cash balance, and can record trades (buy/sell, quantity, price, and date) for any tracked equity.
- **Holdings + transactions view:** The trades index shows current positions, average costs, latest market prices (pulled from cached `DailyPrice` records), net gains, cash balance, and a history table of every trade.
- **Net worth chart:** `PortfolioSnapshot` records capture daily cash, positions value, and net worth so the UI can render a chart of your portfolio value over the last 90 days using Chartkick.
- **Background snapshot tooling:** Creating a trade flags the user for a snapshot backfill, and `PortfolioSnapshotBackfill` plus `UpdatePortfolioSnapshotsJob` ensure the cached values stay current.
- **Market data sync:** `Stock#sync_daily_prices!` calls the MarketData::Eodhd service to hydrate historical daily prices for seeded tickers, and the seeds script downloads ~300 days of data for a small curated watchlist.

## Architecture & data model

- **Models:** `User` owns `trades` and `portfolio_snapshots`, `Trade` stores quantity/price/side info, `Stock` tracks symbol/exchange metadata, and `DailyPrice` caches historical OHLC data per stock.
- **API integration:** The EODHD API (via `MarketData::Eodhd`) supplies refreshed price data. Daily prices are stored locally to avoid hitting the API on every page render.
- **Snapshot workflow:** Snapshots are generated via `User#snapshot_hash`, which combines cash balance plus current position values, and deduplicated rows are upserted by the backfill service or asynchronous job.

## Getting started

1. `bundle install` to fetch gems (Rails 8.1, Chartkick, Devise, etc.).
2. Configure your PostgreSQL database in `config/database.yml`, then run `bin/rails db:create db:migrate`.
3. Seed a few symbols and download historical prices with `bin/rails db:seed`.
4. Start the server with `bin/rails server` and visit `http://localhost:3000`; devise will prompt you to register.

## Environment variables

- `EODHD_API_TOKEN`: required for `MarketData::Eodhd` to download end-of-day data. Set this in your environment or `.env` when running seeds, the sync job, or any request that needs fresh pricing.

## Maintenance & development notes

- Run `bin/rails test` (or `bundle exec rails test`) to exercise the existing test suite.
- The seeded symbols live in `db/seeds.rb`; feel free to add more and rerun `Stock#sync_daily_prices!`.
- Snapshot backfill runs automatically when visiting the trades index, but `UpdatePortfolioSnapshotsJob` can be scheduled via your background processor or manually invoked (`bin/rails runner UpdatePortfolioSnapshotsJob.perform_now`).

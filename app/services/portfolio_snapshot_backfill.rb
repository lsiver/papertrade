require "set"

class PortfolioSnapshotBackfill
  def self.call(user:, from:, to:)
    existing = user.portfolio_snapshots.where(date: from..to).pluck(:date).to_set
    missing_dates = (from..to).reject { |d| existing.include?(d) }
    return 0 if missing_dates.empty?

    rows = missing_dates.map { |d| user.snapshot_hash(as_of: d) }
    PortfolioSnapshot.upsert_all(rows, unique_by: %i[user_id date])
    missing_dates.length
  end
end

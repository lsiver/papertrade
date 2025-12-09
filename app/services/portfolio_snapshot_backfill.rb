require "set"

class PortfolioSnapshotBackfill
  def self.call(user:, from:, to:, force: false)
    dates = (from..to).to_a
    unless force
      existing = user.portfolio_snapshots.where(date: from..to).pluck(:date).to_set
      dates.reject! { |d| existing.include?(d) }
    end

    return 0 if dates.empty?

    rows = dates.map { |d| user.snapshot_hash(as_of: d) }
    PortfolioSnapshot.upsert_all(rows, unique_by: %i[user_id date])
    dates.length
  end
end

class UpdatePortfolioSnapshotsJob < ApplicationJob
  queue_as :default

  def perform(as_of: Date.today)
    users = User.joins(:trades).distinct
    rows = users.map { |u| u.snapshot_hash(as_of: as_of) }

    PortfolioSnapshot.upsert_all(rows, unique_by: %i[user_id date]) if rows.any?
    # Do something later
  end
end

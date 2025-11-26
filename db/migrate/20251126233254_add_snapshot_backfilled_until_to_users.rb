class AddSnapshotBackfilledUntilToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :snapshots_backfilled_until, :date
  end
end

class AddSnapshotNeedsFullBackfillToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :snapshot_needs_full_backfill, :boolean, default: false, null: false
  end
end

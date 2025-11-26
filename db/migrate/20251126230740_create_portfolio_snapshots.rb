class CreatePortfolioSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :portfolio_snapshots do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :cash, null: false, precision: 15, scale: 4
      t.decimal :positions_value, null: false, precision: 15, scale: 4
      t.decimal :net_worth, null: false, precision: 15, scale: 4

      t.timestamps
    end
    add_index :portfolio_snapshots, [ :user_id, :date ], unique: true
  end
end

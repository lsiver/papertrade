class CreateTrades < ActiveRecord::Migration[8.1]
  def change
    create_table :trades do |t|
      t.references :user, null: false, foreign_key: true
      t.references :stock, null: false, foreign_key: true
      t.integer :side, null: false
      t.decimal :quantity, null: false, precision: 15, scale: 4
      t.decimal :price, null: false, precision: 15, scale: 4
      t.date :trade_date, null: false

      t.timestamps
    end

    add_index :trades, [ :user_id, :stock_id, :trade_date ]
  end
end

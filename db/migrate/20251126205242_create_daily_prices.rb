class CreateDailyPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_prices do |t|
      t.references :stock, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :open, precision: 15, scale: 4
      t.decimal :high, precision: 15, scale: 4
      t.decimal :low, precision: 15, scale: 4
      t.decimal :close, precision: 15, scale: 4
      t.bigint :volume
      t.string :source, null: false, default: "eodhd"

      t.timestamps
    end

    add_index :daily_prices, [ :stock_id, :date ], unique: true
  end
end

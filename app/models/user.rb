class User < ApplicationRecord
  require "bigdecimal/util"
  STARTING_CASH = 100_000.to_d
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :trades, dependent: :destroy
  has_many :portfolio_snapshots, dependent: :destroy


  def cash_balance(as_of: Date.today)
    t = trades.where("trade_date <= ?", as_of)

    buys  = t.buy.sum("quantity * price")
    sells = t.sell.sum("quantity * price")

    STARTING_CASH - buys + sells
  end

  def net_worth(as_of: Date.today)
    t = trades.where("trade_date <= ?", as_of)

    qty_by_stock = t.group(:stock_id).sum(
      Arel.sql("CASE WHEN side = #{Trade.sides[:buy]} THEN quantity ELSE -quantity END")
    )

    prices = DailyPrice.latest_closes_for(stock_ids: qty_by_stock.keys, as_of: as_of)

    positions_value = qty_by_stock.sum do |stock_id, qty|
      qty.to_d * (prices[stock_id] || 0)
    end

    cash_balance(as_of: as_of) + positions_value
  end

  def snapshot_hash(as_of:)
    cash = cash_balance(as_of: as_of)

    t = trades.where("trade_date <= ?", as_of)
    qty_by_stock = t.group(:stock_id).sum(
      Arel.sql("CASE WHEN side = #{Trade.sides[:buy]} THEN quantity ELSE -quantity END")
    )

    prices = DailyPrice.latest_closes_for(stock_ids: qty_by_stock.keys, as_of: as_of)

    positions_value = qty_by_stock.sum do | stock_id, qty|
      qty.to_d * (prices[stock_id] || 0)
    end

    {
      user_id: id,
      date: as_of,
      cash: cash,
      positions_value: positions_value,
      net_worth: cash + positions_value,
      created_at: Time.current,
      updated_at: Time.current
    }
  end
end

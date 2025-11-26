class User < ApplicationRecord
  require "bigdecimal/util"
  STARTING_CASH = 100_100.to_d
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :trades, dependent: :destroy


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
end

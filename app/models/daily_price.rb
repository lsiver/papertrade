class DailyPrice < ApplicationRecord
  belongs_to :stock
  validates :date, presence: true

  def self.latest_closes_for(stock_ids:, as_of: Date.today)
    where(stock_id: stock_ids)
      .where("date <= ?", as_of)
      .select("DISTINCT ON (stock_id) stock_id, close, date")
      .order("stock_id, date DESC")
      .each_with_object({}) { |r, h| h[r.stock_id] = r.close }
  end
end

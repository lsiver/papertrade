class DailyPrice < ApplicationRecord
  belongs_to :stock
  validates :date, presence: true

  def self.latest_records_for(stock_ids:, as_of: Date.today)
    return {} if stock_ids.blank?

    where(stock_id: stock_ids)
      .where("date <= ?", as_of)
      .select("DISTINCT ON (stock_id) daily_prices.*")
      .order("stock_id, date DESC")
      .index_by(&:stock_id)
  end

  def self.latest_closes_for(stock_ids:, as_of: Date.today)
    latest_records_for(stock_ids: stock_ids, as_of: as_of).transform_values(&:close)
  end

  def self.closest_for(stock_id:, date:)
    find_by(stock_id: stock_id, date: date) ||
      where(stock_id: stock_id).where("date < ?", date).order(date: :desc).first ||
      where(stock_id: stock_id).where("date > ?", date).order(date: :asc).first
  end
end

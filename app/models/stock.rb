class Stock < ApplicationRecord
  has_many :trades, dependent: :restrict_with_error
  has_many :daily_prices, dependent: :destroy

  before_validation :normalize_symbol

  validates :symbol, presence: true, uniqueness: true

  def eodhd_symbol
    "#{symbol}.US"
  end

  def sync_daily_prices!(from: 1.month.ago.to_date, to: Date.today)
    client = MarketData::Eodhd.new
    rows = client.fetch_eod(eodhd_symbol, from: from, to: to)

    payload = rows.map do |r|
      {
        stock_id: id,
        date: Date.parse(r["date"]),
        open: r["open"],
        high: r["high"],
        low: r["low"],
        close: r["close"],
        volume: r["volume"],
        source: "eodhd",
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    DailyPrice.upsert_all(payload, unique_by: %i[stock_id date]) if payload.any?
  end

  private

  def normalize_symbol
    self.symbol = symbol.to_s.strip.upcase
  end

  def self.find_or_create_by_symbol!(sym)
    sym = sym.to_s.strip.upcase
    find_or_create_by!(symbol: sym)
  end
end

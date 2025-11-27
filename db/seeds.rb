# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
symbols = %w[AAPL TSLA AMD NVDA ONDS OPEN NIO PLUG BBAI GOOGL AAL SOFI GOOG F]

stocks = symbols.map { |sym| Stock.find_or_create_by_symbol!(sym) }

stocks.each do |stock|
  stock.sync_daily_prices!(from: 300.days.ago.to_date, to: Date.today)
end

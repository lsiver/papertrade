class StocksController < ApplicationController
  before_action :authenticate_user!

  def close_price
    stock = Stock.find(params[:id])
    date = Date.parse(params[:date])

    dp = DailyPrice.closest_for(stock_id: stock.id, date: date)

    render json: dp ? { close: dp.close.to_f, date_used: dp.date.to_s } : { close: nil, date_used: nil }
  rescue ArgumentError
    render json: { error: "invalid date" }, status: :unprocessable_entity
  end

  def price_history
    stock = Stock.find(params[:id])
    history = stock.daily_prices.where("date <= ?", Date.today).order(:date)
    render json: history.map { |dp| [dp.date.to_s, dp.close.to_f] }
  end

  def index
    @stocks = Stock.all
    stock_ids = @stocks.pluck(:id)
    @latest_price_by_stock = DailyPrice.latest_records_for(stock_ids: stock_ids)
  end

  def show
    @stock = Stock.find(params[:id])
    @prices = @stock.daily_prices.order(:date)
  end
end

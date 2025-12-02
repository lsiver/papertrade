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
end

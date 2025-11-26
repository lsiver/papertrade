class TradesController < ApplicationController
  before_action :authenticate_user!

  def index
    @trades = current_user.trades.includes(:stock).order(trade_date: :desc, created_at: :desc)
    @net_worth = current_user.net_worth
    @cash_balance = current_user.cash_balance(as_of: Date.today)
  end

  def new
    @trade = Trade.new(trade_date: Date.today)
  end

  def create
    stock = Stock.find_or_create_by_symbol!(trade_params[:symbol])
    @trade = current_user.trades.new(trade_params.except(:symbol).merge(stock: stock))

    if @trade.save
      redirect_to trades_path, notice: "Trade created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def trade_params
    params.require(:trade).permit(:symbol, :side, :quantity, :price, :trade_date)
  end
end

class TradesController < ApplicationController
  before_action :authenticate_user!

  def index
    @trades = current_user.trades.includes(:stock).order(trade_date: :desc, created_at: :desc)
    @net_worth = current_user.net_worth
    @cash_balance = current_user.cash_balance(as_of: Date.today)

    from = 90.days.ago.to_date
    to = Date.today

    if current_user.snapshots_backfilled_until.nil? || current_user.snapshots_backfilled_until < to
      PortfolioSnapshotBackfill.call(user: current_user, from: from, to: to)
      current_user.update_column(:snapshots_backfilled_until, to)
    end
    # PortfolioSnapshotBackfill.call(user: current_user, from: from, to: to)


    @snapshots = current_user.portfolio_snapshots.where(date: from..to).order(:date)
    @chart_labels = @snapshots.map { |s| s.date.to_s }
    @chart_values = @snapshots.map { |s| s.net_worth.to_f }
  end

  def new
    @trade = Trade.new(trade_date: Date.today)
    @stocks = Stock.order(:symbol)
  end

  def create
    @trade = current_user.trades.new(trade_params)

    if @trade.save
      redirect_to trades_path, notice: "Trade created."
    else
      @stocks = Stock.order(:symbol)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def trade_params
    params.require(:trade).permit(:stock_id, :side, :quantity, :price, :trade_date)
  end
end

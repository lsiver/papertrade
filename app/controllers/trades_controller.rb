class TradesController < ApplicationController
  before_action :authenticate_user!

  def index
    @trades = current_user.trades.includes(:stock).order(trade_date: :desc, created_at: :desc)
    @net_worth = current_user.net_worth
    @cash_balance = current_user.cash_balance(as_of: Date.today)
    @holdings = build_holdings(@trades)

    snapshot_window_from = 90.days.ago.to_date
    snapshot_window_to = Date.today
    needs_full_backfill = current_user.snapshot_needs_full_backfill?
    earliest_trade_date = current_user.trades.minimum(:trade_date)
    backfill_from = needs_full_backfill ? (earliest_trade_date || snapshot_window_from) : snapshot_window_from

    should_backfill = needs_full_backfill ||
      current_user.snapshots_backfilled_until.nil? ||
      current_user.snapshots_backfilled_until < snapshot_window_to

    if should_backfill
      PortfolioSnapshotBackfill.call(
        user: current_user,
        from: backfill_from,
        to: snapshot_window_to,
        force: needs_full_backfill
      )
      current_user.update!(
        snapshots_backfilled_until: snapshot_window_to,
        snapshot_needs_full_backfill: false
      )
    end

    @snapshots = current_user.portfolio_snapshots.where(date: snapshot_window_from..snapshot_window_to).order(:date)
    @chart_labels = @snapshots.map { |s| s.date.to_s }
    @chart_values = @snapshots.map { |s| s.net_worth.to_f }
  end

  def new
    @trade = Trade.new(trade_date: Date.today)
    @stocks = Stock.order(:symbol)
    @cash_balance = current_user.cash_balance(as_of: Date.today)
  end

  def create
    @trade = current_user.trades.new(trade_params)

    if @trade.save
      current_user.update!(snapshot_needs_full_backfill: true)
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

  def build_holdings(trades)
    grouped_trades = trades.group_by(&:stock)
    stock_ids = grouped_trades.keys.map(&:id)
    latest_prices = DailyPrice.latest_records_for(stock_ids: stock_ids)

    grouped_trades.sort_by { |stock, _| stock.symbol }.map do |stock, stock_trades|
      buy_qty = 0
      sell_qty = 0
      buy_cost = 0.to_d
      sell_proceeds = 0.to_d

      stock_trades.each do |trade|
        qty = trade.quantity
        price = trade.price.to_d

        if trade.buy?
          buy_qty += qty
          buy_cost += qty * price
        else
          sell_qty += qty
          sell_proceeds += qty * price
        end
      end

      net_qty = buy_qty - sell_qty

      average_price = case
      when net_qty.positive?
        buy_qty.positive? ? buy_cost / buy_qty : nil
      when net_qty.negative?
        sell_qty.positive? ? sell_proceeds / sell_qty : nil
      else
        buy_qty.positive? ? buy_cost / buy_qty : nil
      end

      price_record = latest_prices[stock.id]
      current_price = price_record&.close

      net_value = if current_price && average_price
        if net_qty.negative?
          net_qty.abs * (average_price - current_price)
        else
          net_qty * (current_price - average_price)
        end
      end

      {
        stock: stock,
        net_qty: net_qty,
        average_price: average_price,
        current_price: current_price,
        price_date: price_record&.date,
        net_value: net_value
      }
    end
  end
end

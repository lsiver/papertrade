class Trade < ApplicationRecord
  belongs_to :user
  belongs_to :stock

  enum :side, { buy: 0, sell: 1 }

  validates :side, presence: true
  validates :trade_date, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  attr_accessor :symbol
end

require "net/http"
require "json"

module MarketData
  class Eodhd
    BASE = "https://eodhd.com/api/eod".freeze

    def initialize(api_token: ENV.fetch("EODHD_API_TOKEN"))
      @api_token = api_token
    end

    def fetch_eod(symbol_with_exchange, from: nil, to: nil)
      uri = URI("#{BASE}/#{symbol_with_exchange}")
      params = { api_token: @api_token, fmt: "json", period: "d" }
      params[:from] = from.to_s if from
      params[:to]   = to.to_s if to
      uri.query = URI.encode_www_form(params)

      res = Net::HTTP.get_response(uri)
      raise "EODHD error #{res.code}: #{res.body[0, 200]}" unless res.is_a?(Net::HTTPSuccess)

      JSON.parse(res.body)
    end
  end
end

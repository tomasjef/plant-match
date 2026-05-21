require "net/http"
require "json"

module Perenual
  class Client
    BASE_URL = "https://perenual.com/api/v2"
    TIMEOUT_SECONDS = 8

    def initialize(api_key: ENV.fetch("PERENUAL_API_KEY"))
      @api_key = api_key
    end

    def species_list(params = {})
      get("/species-list", params)
    end

    def species_details(id)
      get("/species/details/#{id}")
    end

    private

    def get(path, params = {})
      uri = URI("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params.compact.merge(key: @api_key))

      response = perform_request(uri)

      raise "Perenual error: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise "Perenual returned invalid JSON: #{e.message}"
    end

    def perform_request(uri)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: TIMEOUT_SECONDS, read_timeout: TIMEOUT_SECONDS) do |http|
        http.get(uri)
      end
    end
  end
end

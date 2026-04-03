class TrefleClient
  include HTTParty

  base_uri ENV["TREFLE_API_URL"]

  TREFLE_TOKEN = ENV["TREFLE_API_TOKEN"]

  private_constant :TREFLE_TOKEN

  def get_all_plants(page: 1, params: {})
    call("/plants", params: { page:, **params })
  end

  def get_plant(id)
    call("/plants/#{id}")
  end

  private

  def call(path, verb: :get, params: {})
    self.class.send(verb, path, query: params, headers: { "Authorization" => "Token #{TREFLE_TOKEN}" })
  end
end

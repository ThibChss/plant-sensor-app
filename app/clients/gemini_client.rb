class GeminiClient
  attr_reader :client

  def initialize(event: false)
    @client = Gemini.new(
      credentials: {
        service: 'generative-language-api',
        api_key: Rails.application.credentials.gemini.api_key,
        version: 'v1beta'
      },
      options: {
        model: 'gemini-2.5-flash',
        server_sent_events: event
      }
    )
  end
end

# frozen_string_literal: true

require "net/http"

# Thin wrapper around the Perplexity chat-completions API used by ResearchJob.
class PerplexityClient
  class Error < StandardError; end
  class TransientError < Error; end

  ENDPOINT = URI("https://api.perplexity.ai/chat/completions")
  MODEL = "sonar-pro"
  SYSTEM_PROMPT = "You are a research assistant preparing background material for an executive briefing. " \
                  "Be factual, specific, and concise. Prefer recent information and cite concrete facts."
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 120

  # Runs one research query. Returns { content: String, sources: [{ title:, url: }] }.
  def research(prompt)
    response = post_chat(prompt)

    case response
    when Net::HTTPSuccess
      parse_success(response.body)
    when Net::HTTPTooManyRequests, Net::HTTPServerError
      raise TransientError, "Perplexity returned #{response.code}"
    else
      raise Error, "Perplexity returned #{response.code}: #{response.body.to_s.truncate(200)}"
    end
  rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError => e
    raise TransientError, "Perplexity request failed: #{e.message}"
  end

  private

  def post_chat(prompt)
    request = Net::HTTP::Post.new(ENDPOINT)
    request["Authorization"] = "Bearer #{ENV.fetch('PERPLEXITY_API_KEY')}"
    request["Content-Type"] = "application/json"
    request.body = {
      model: MODEL,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: prompt }
      ]
    }.to_json

    Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true,
                    open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
      http.request(request)
    end
  end

  def parse_success(body)
    payload = JSON.parse(body)
    content = payload.dig("choices", 0, "message", "content").to_s
    sources = Array(payload["search_results"]).map do |result|
      { title: result["title"].to_s, url: result["url"].to_s }
    end
    if sources.empty?
      sources = Array(payload["citations"]).map { |url| { title: url, url: url } }
    end

    { content: content, sources: sources }
  rescue JSON::ParserError
    raise Error, "Perplexity returned unparseable JSON"
  end
end

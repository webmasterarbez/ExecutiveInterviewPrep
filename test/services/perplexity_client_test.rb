require "test_helper"
require "minitest/mock"

class PerplexityClientTest < ActiveSupport::TestCase
  setup do
    ENV["PERPLEXITY_API_KEY"] = "test-key"
  end

  teardown do
    ENV.delete("PERPLEXITY_API_KEY")
  end

  test "parses content and search results from a successful response" do
    body = {
      choices: [ { message: { content: "Acme builds robots." } } ],
      search_results: [
        { title: "Acme — About", url: "https://acme.test/about" },
        { title: "Acme funding", url: "https://news.test/acme" }
      ]
    }.to_json

    stub_response(Net::HTTPOK, body) do
      result = PerplexityClient.new.research("Tell me about Acme")

      assert_equal "Acme builds robots.", result[:content]
      assert_equal 2, result[:sources].size
      assert_equal "Acme — About", result[:sources].first[:title]
      assert_equal "https://acme.test/about", result[:sources].first[:url]
    end
  end

  test "falls back to citations when search results are absent" do
    body = {
      choices: [ { message: { content: "Facts." } } ],
      citations: [ "https://source.test/1" ]
    }.to_json

    stub_response(Net::HTTPOK, body) do
      result = PerplexityClient.new.research("query")

      assert_equal [ { title: "https://source.test/1", url: "https://source.test/1" } ], result[:sources]
    end
  end

  test "raises TransientError on 429" do
    stub_response(Net::HTTPTooManyRequests, "rate limited") do
      assert_raises PerplexityClient::TransientError do
        PerplexityClient.new.research("query")
      end
    end
  end

  test "raises TransientError on 500" do
    stub_response(Net::HTTPInternalServerError, "boom") do
      assert_raises PerplexityClient::TransientError do
        PerplexityClient.new.research("query")
      end
    end
  end

  test "raises Error on other failure codes" do
    stub_response(Net::HTTPUnauthorized, "bad key") do
      assert_raises PerplexityClient::Error do
        PerplexityClient.new.research("query")
      end
    end
  end

  test "raises KeyError when the API key is missing" do
    ENV.delete("PERPLEXITY_API_KEY")

    assert_raises KeyError do
      PerplexityClient.new.research("query")
    end
  end

  private

  # Builds a real Net::HTTPResponse subclass instance carrying `body` and runs
  # the block with Net::HTTP.start stubbed to return it.
  def stub_response(response_class, body, &block)
    response = response_class.new("1.1", http_code_for(response_class), "")
    response.define_singleton_method(:body) { body }

    # A callable so minitest doesn't invoke the consumer's Net::HTTP.start block.
    Net::HTTP.stub(:start, ->(*_args, &_blk) { response }, &block)
  end

  def http_code_for(response_class)
    Net::HTTPResponse::CODE_TO_OBJ.key(response_class) || "200"
  end
end

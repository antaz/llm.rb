# frozen_string_literal: true

module LLM
  require "net/http"
  require "uri"
  require "json"
  require "LLM/http/client"
  require "LLM/adapter"
  require "LLM/response"

  class OpenAI < Adapter
    BASE_URL = "https://api.openai.com/v1"
    ENDPOINT = "/chat/completions"
    DEFAULT_PARAMS = {
      model: "gpt-4o-mini",
      temperature: 0.7
    }.freeze

    attr_reader :http

    def initialize(secret)
      @uri = URI.parse("#{BASE_URL}#{ENDPOINT}")
      @http = Net::HTTP.new(@uri.host, @uri.port).tap do |http|
        http.use_ssl = true
        http.extend(HTTPClient)
      end
      super
    end

    def complete(prompt, params = {})
      body = {
        messages: [{role: "user", content: prompt}],
        **DEFAULT_PARAMS,
        **params
      }

      response = @http.request(@uri, @secret, body)
      case response
      when Net::HTTPSuccess
        choices = JSON.parse(response.body)["choices"]
        choices.map { |choice| Response.new(choice["message"]["role"], choice["message"]["content"]) }
      when Net::HTTPUnauthorized
        raise LLM::AuthError
      else
        raise LLM::NetError
      end
    end
  end
end
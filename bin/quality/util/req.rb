#!/usr/bin/env ruby
# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'

module Net
  class HTTPRequest # rubocop:disable Style/Documentation
    def self.lark_open_auth(refresh: false)
      @lark_open_auth = nil if refresh
      return @lark_open_auth unless @lark_open_auth.nil?

      # fetch token
      # @huoyunjie 搭建的轻服务，获取的是 @huoyunjie 的 token，待替换
      res = Net::HTTP.get(URI('https://cloudapi.bytedance.net/faas/services/ttubg9/invoke/updateUserAccessToken'))
      token = JSON.parse(res)&.dig('token')
      raise 'fetch token failed' if token.nil? || token.empty?

      @lark_open_auth = token
    end

    # 给 request 对象添加 json 配置
    def json!
      self['Content-Type'] = 'application/json'
      self['accept'] = 'application/json'
      self
    end

    # 给 request 对象添加 auth 信息
    def auth!(refresh: false)
      self['Authorization'] = "Bearer #{Net::HTTPRequest.lark_open_auth(refresh: refresh)}"
      self
    end

    # @return [Hash]
    def send
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(self) }
      body = JSON.parse(res.body) || {}
      code = body['code']
      throw "unexpected response, missing code. res: #{res}" if code.nil?
      throw "unexpected code: #{code}" unless code.zero? || code == 200
      body
    end
  end
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require 'base64'

QUALITY_URL_BASE = 'https://lark-code-quality.bytedance.net'
YY_GROUP_ID = 25
YY_URL_ENCODED_NAME = '%E5%BE%90%E9%A2%96%E9%80%B8'

def quality_auth_token
  encoded = 'aHR0cHM6Ly90b3N2LmJ5dGVkLm9yZy9vYmovZWUtaW5mcmEtaW9zL3F1YWxpdHlfYXV0aF90b2tlbg=='
  `curl -fsSL #{Base64.decode64 encoded}`.strip
end
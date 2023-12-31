#!/usr/bin/env ruby
# frozen_string_literal: true

require 'base64'

# https://bits.bytedance.net/bitsApi/api/code_check/v2
API_URL_BASE = Base64.decode64 'aHR0cHM6Ly9iaXRzLmJ5dGVkYW5jZS5uZXQvYml0c0FwaS9hcGkvY29kZV9jaGVjay92Mg=='
API_COOKIE_VALUE = 'mobile_dev_platform_sid=cd516c5f8d5fa94ca8da2b664ad5ea0d'

# https://bits.bytedance.net/openapi
OPEN_API_URL_BASE = Base64.decode64 'aHR0cHM6Ly9iaXRzLmJ5dGVkYW5jZS5uZXQvb3BlbmFwaQ=='

# https://bits.bytedance.net/bytebus/devops
VIEW_URL_BASE = Base64.decode64 'aHR0cHM6Ly9iaXRzLmJ5dGVkYW5jZS5uZXQvYnl0ZWJ1cy9kZXZvcHM='

# http://tosv.byted.org/obj/ee-infra-ios
TOS_URL_BASE = Base64.decode64 'aHR0cDovL3Rvc3YuYnl0ZWQub3JnL29iai9lZS1pbmZyYS1pb3M='
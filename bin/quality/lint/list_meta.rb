#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative '../util/sheet'

# 获取 https://bytedance.feishu.cn/wiki/LCfYwmusqi7ut9kcj8scLX5DnuH 里的 bitable 信息
sheet = Sheet.new(token: 'XFqNs8bRahwM2XtprqPcHxRYnlg', sheet_id: '')
puts sheet.fetch_meta.to_json
# frozen_string_literal: true

# rubocop:disable Layout

require_relative '../../util'

module Lark
  module Demo
    class Builder
      # 为 Assets 生成内容，存于 Assets.xcassets/Contents.json
      def gen_assets_content
        <<-CONTENT
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

        CONTENT
      end

      # 为 AppIcon 生成内容，存于 Assets.xcassets/AppIcon.appiconset/Contents.json
      def gen_assets_appicon_content
        template = <<-CONF
{
  "images" : [
<% configs.each_with_index do |item, index| %>
    {
      "idiom" : "<%= item[:idiom] %>",
      "scale" : "<%= item[:scale] %>x",
      "size" : "<%= item[:size] %>x<%= item[:size] %>"
    }<%= ',' if index < (configs.size - 1) %>
<% end %>
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
        CONF

        configs = [
          { :idiom => 'iphone', :size => 20, :scale => 2 },
          { :idiom => 'iphone', :size => 20, :scale => 3 },
          { :idiom => 'iphone', :size => 29, :scale => 2 },
          { :idiom => 'iphone', :size => 29, :scale => 3 },
          { :idiom => 'iphone', :size => 40, :scale => 2 },
          { :idiom => 'iphone', :size => 40, :scale => 3 },
          { :idiom => 'iphone', :size => 60, :scale => 2 },
          { :idiom => 'iphone', :size => 60, :scale => 3 },

          { :idiom => 'ipad', :size => 20, :scale => 1 },
          { :idiom => 'ipad', :size => 20, :scale => 2 },
          { :idiom => 'ipad', :size => 29, :scale => 1 },
          { :idiom => 'ipad', :size => 29, :scale => 2 },
          { :idiom => 'ipad', :size => 40, :scale => 1 },
          { :idiom => 'ipad', :size => 40, :scale => 2 },
          { :idiom => 'ipad', :size => 76, :scale => 1 },
          { :idiom => 'ipad', :size => 76, :scale => 2 },
          { :idiom => 'ipad', :size => 83.5, :scale => 2 },

          { :idiom => 'ios-marketing', :size => 1024, :scale => 1 },
          { :idiom => 'ios-marketing', :size => 20, :scale => 2 }
        ]

        Utils.render(template, { :configs => configs })
      end

      # 生成 main.swift 内容
      def gen_main_swift
        File.read(File.expand_path('resource/main.swift', __dir__))
      end

      # 生成 Info.plist 内容
      def gen_info_plist
        template = File.read(File.expand_path('resource/Info.plist', __dir__))
        params = {
          'languages' => %w[
          en_US zh_CN ja_JP id_ID de_DE es_ES fr_FR it_IT
          pt_BR vi_VN ru_RU zh_TW zh_HK hi_IN th_TH ko_KR ms_MY
        ],
          'background_modes' => %w[
          audio fetch location processing
          remote-notification voip
        ]
        }
        Utils::render(template, params)
      end

      # 生成 LaunchScreen.storyboard 内容
      def gen_launch_screen_storyboard
        File.read(File.expand_path('resource/LaunchScreen.storyboard', __dir__))
      end

    end
  end
end

# rubocop:enable Layout

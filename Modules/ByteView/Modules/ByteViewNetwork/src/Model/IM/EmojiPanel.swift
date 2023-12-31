//
//  EmojiPanel.swift
//  ByteViewNetwork
//
//  Created by chenyizhuo on 2022/3/9.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

public typealias Emojis = EmojiPanel.Emojis

/// Im_V1_EmojiPanel
public struct EmojiPanel: Equatable {
    /// 有序
    public var emojisOrder: [Emojis]

    public init(emojisOrder: [Emojis]) {
        self.emojisOrder = emojisOrder
    }

    public struct Emojis: Equatable {

        /// 分类：目前只有默认和自定义
        /// 分栏：默认是一个分栏，自定义可以有多个分栏
        public var type: EmojiPanelType

        /// 分栏的 icon
        public var iconKey: String

        /// 分类的 title, 返回国际化的
        public var title: String

        /// hover 上去展示的文案，返回国际化的
        public var source: String

        public var keys: [EmojiKey]

        public init(type: EmojiPanelType, iconKey: String, title: String, source: String, keys: [EmojiKey]) {
            self.type = type
            self.iconKey = iconKey
            self.title = title
            self.source = source
            self.keys = keys
        }

        public struct EmojiKey: Equatable {
            public var key: String

            public var selectedSkinKey: String

            public init(key: String, selectedSkinKey: String) {
                self.key = key
                self.selectedSkinKey = selectedSkinKey
            }
        }

    }

    public enum EmojiPanelType: Int {
        case unknown // = 0
        /// 默认
        case `default` // = 1
        /// 自定义
        case custom // = 2
    }
}

extension EmojiPanel.Emojis.EmojiKey: CustomStringConvertible {
    public var description: String {
        String(indent: "EmojiPanel.Emojis.EmojiKey",
               "key: \(key)",
               "selectedSkinKey: \(selectedSkinKey)")
    }
}


extension EmojiPanel.Emojis: CustomStringConvertible {
    public var description: String {
        String(indent: "EmojiPanel.Emojis",
               "type: \(type)",
               "iconKey: \(iconKey)",
               "title: \(title)",
               "source: \(source)",
               "keys: \(keys)"
        )
    }
}


extension EmojiPanel: CustomStringConvertible {
    public var description: String {
        String(indent: "EmojiPanel",
               "emojisOrder: \(emojisOrder)"
        )
    }
}

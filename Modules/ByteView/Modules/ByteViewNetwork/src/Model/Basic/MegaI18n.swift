//
//  MegaI18n.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_MegaI18n
public struct MegaI18n: Equatable {
    public init(key: String, data: [String: I18nData]) {
        self.key = key
        self.data = data
    }

    public var key: String

    public var data: [String: I18nData]

    public struct I18nData: Equatable {
        public init(type: I18nData.TypeEnum, payload: String) {
            self.type = type
            self.payload = payload
        }

        public var type: I18nData.TypeEnum

        /// 配合 type 使用
        public var payload: String

        public enum TypeEnum: Int, Hashable {
            /// 什么都不做
            case unknown // = 0

            /// 字符串，将占位符替换为 payload
            case string // = 1

            /// 超链接，payload 为超链接的地址
            case link // = 2

            /// 可点击，payload 为触发事件的名称
            case click // = 3

            /// strong，加强显示，不需要 payload
            case em // = 4
        }
    }
}

extension MegaI18n: CustomStringConvertible {
    public var description: String {
        String(indent: "MegaI18n",
               "key: \(key)",
               "data: \(data.mapValues({ "\($0.type)" }))"
        )
    }
}

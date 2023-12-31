//
//  DraftModel.swift
//  Lark
//
//  Created by 齐鸿烨 on 2017/9/6.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkUIKit
import LarkBaseKeyboard

public struct UploadedImageDraft: Persistable {
    public static let `default` = UploadedImageDraft()

    public var key: String = ""
    public var url: String = ""
    public var width: Int32 = 0
    public var height: Int32 = 0

    public init(key: String = "", url: String = "", width: Int32 = 0, height: Int32 = 0) {
        self.key = key
        self.url = url
        self.width = width
        self.height = height
    }

    public init(unarchive: [String: Any]) {
        guard let key = unarchive["key"] as? String else {
            return
        }

        self.key = key
        self.url = unarchive["url"] as? String ?? ""
        self.width = unarchive["width"] as? Int32 ?? 0
        self.height = unarchive["height"] as? Int32 ?? 0
    }

    public func archive() -> [String: Any] {
        return [
            "key": self.key,
            "url": self.url,
            "width": self.width,
            "height": self.height
        ]
    }
}

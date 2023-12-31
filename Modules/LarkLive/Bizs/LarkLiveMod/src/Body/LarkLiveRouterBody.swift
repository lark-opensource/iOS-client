//
//  LarkLiveRouterBody.swift
//  ByteView
//
//  Created by panzaofeng on 2021/10/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import EENavigator

/// 定义自己业务打开的Body
public struct LarkLiveRouterBody: CodablePlainBody {
    public static let pattern: String = "//client/larklive"

    public let url: URL

    public init(url: URL) {
        self.url = url
    }
}

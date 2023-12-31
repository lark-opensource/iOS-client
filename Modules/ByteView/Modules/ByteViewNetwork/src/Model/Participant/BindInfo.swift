//
//  BindInfo.swift
//  ByteViewCommon
//
//  Created by wulv on 2021/11/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public struct BindInfo: Hashable {
    public let id: String
    public let type: PSTNInfo.BindType
    public init(id: String, type: PSTNInfo.BindType) {
        self.id = id
        self.type = type
    }
}

//
//  TenantTag.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/18.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_TenantTag
public enum TenantTag: Int, Hashable {
    /// 标准租户（大B租户）
    case standard // = 0
    /// 未定义租户
    case undefined // = 1
    /// 普通租户（小B租户）
    case simple // = 2
}

extension TenantTag: CustomStringConvertible {
    public var description: String {
        switch self {
        case .standard:
            return "standard"
        case .undefined:
            return "undefined"
        case .simple:
            return "simple"
        }
    }
}

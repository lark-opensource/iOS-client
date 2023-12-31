//
//  RequestUtil.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

final class RequestUtil {
    @inline(__always)
    static func normalizedBreakoutRoomId(_ breakoutRoomId: String?) -> String? {
        if let value = breakoutRoomId, !value.isEmpty, breakoutRoomId != "1" {
            return value
        } else {
            return nil
        }
    }
}

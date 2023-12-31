//
//  BTStatisticUtils.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/9/1.
//

import Foundation

final class BTStatisticUtils {
    private static func uuid() -> String {
        return UUID().uuidString
    }

    static func generateTraceId() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        return "\(Self.uuid())-\(timestamp)"
    }
}

//
//  LKTracing.swift
//  LKTracing
//
//  Created by Miaoqi Wang on 2019/11/29.
//

import Foundation

enum Const {
    static let version: String = "1"
    static let formatUUIDLength: Int = 8
}

func generateSpan() -> String {
    let pureUuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    let formatUUID = String(pureUuid.prefix(min(Const.formatUUIDLength, pureUuid.count)))
    return formatUUID
}

/// general tracing
public final class LKTracing: NSObject {
    static let shared = LKTracing()

    let formatId: String

    override init() {
        self.formatId = "\(Const.version)-\(generateSpan())"
        super.init()
    }

    /// tracing identifier which keeping same during one app life cycle
    @objc public static var identifier: String {
        return shared.formatId
    }

    /// create new span
    @objc public static func newSpan(traceId: String) -> String {
        return "\(traceId)-\(generateSpan())"
    }
}

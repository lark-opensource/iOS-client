//
//  LKTracing.swift
//  LarkWebViewDemo
//
//  Created by lijuyou on 2020/9/15.
//  Copyright © 2020 bytedance. All rights reserved.

import Foundation
import LarkOPInterface

/// 模拟setupTrace，生成TracingID
public class LKTracing: NSObject {
    static let tracingIdentifier = "spacedemo-trace"
    static let shared = LKTracing()
    let formatId: String

    enum Const {
        static let version: String = "1"
        static let formatUUIDLength: Int = 8
    }

    override init() {
        self.formatId = "\(Const.version)-\(LKTracing.generateSpan())"
        super.init()
    }

    /// tracing identifier which keeping same during one app life cycle
    @objc public static var identifier: String {
        return shared.formatId
    }

    /// create new span
    @objc
    public static func newSpan(traceId: String) -> String {
        return "\(traceId)-\(LKTracing.generateSpan())"
    }

    static func generateSpan() -> String {
        let pureUuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let formatUUID = String(pureUuid.prefix(min(Const.formatUUIDLength, pureUuid.count)))
        return formatUUID
    }

    static func setupTrace() {
        let config = OPTraceConfig(prefix: tracingIdentifier) { parent -> String in
            return LKTracing.newSpan(traceId: parent)
        }
        OPTraceService.default().setup(config)
    }
}

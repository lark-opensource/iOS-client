//
//  Tracker.swift
//  LarkSnCService
//
//  Created by Bytedance on 2022/8/8.
//

import Foundation

/// 埋点协议
public protocol Tracker {
    /// Tea Tracker，建议使用 track(event:params:)
    /// - Parameters:
    ///   - name: Event Name
    ///   - params: Paramters
    func send(event name: String, params: [AnyHashable: Any]?)
}

public extension Tracker {
    /// Tea Tracker
    /// - Parameter name: Event Name
    func track(event name: String, params: [AnyHashable: Any]? = nil) {
        send(event: name, params: params)
    }
}

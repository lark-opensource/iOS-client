//
//  RustClientPushHandlerManager.swift
//  LarkRustClient
//
//  Created by lvdaqian on 2018/6/15.
//  Copyright © 2018年 linlin. All rights reserved.
//

import Foundation
import SwiftProtobuf

open class BaseRustPushHandler<T: SwiftProtobuf.Message>: RustPushHandler {

    public init() { }

    public func processMessage(payload: Data) {
        if let message = decode(payload: payload) {
            doProcessing(message: message)
        }
    }

    func decode(payload: Data) -> T? {
        do {
            return try T(serializedData: payload, options: .discardUnknownFieldsOption)
        } catch {
            SimpleRustClient.logger.warn("Rust长链接消息解析失败", error: error)
        }
        return nil
    }

    open func doProcessing(message: T) { }
}

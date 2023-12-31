//
//  BaseReachPoint.swift
//  UGContainer
//
//  Created by mochangxing on 2021/1/24.
//

import Foundation
import SwiftProtobuf

public protocol BasePBReachPoint: HideableReachPoint where ReachPointModel: SwiftProtobuf.Message {}

extension BasePBReachPoint {

    /// 反序列化，从二进制数据反序列化为对象
    public static func decode(payload: Data) -> ReachPointModel? {
        do {
            return try ReachPointModel(serializedData: payload, options: .discardUnknownFieldsOption)
        } catch {
            PluginContainerServiceImpl.log.error("decode meet error: \(error)")
        }
        return nil
    }
}

extension BinaryDecodingOptions {
    static var discardUnknownFieldsOption: BinaryDecodingOptions = {
        var options = BinaryDecodingOptions()
        options.discardUnknownFields = true
        return options
    }()
}

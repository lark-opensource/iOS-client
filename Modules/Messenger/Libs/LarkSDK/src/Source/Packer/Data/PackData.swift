//
//  PackData.swift
//  Lark
//
//  Created by liuwanlin on 2018/6/11.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel
import LarkSDKInterface

protocol PackDataItem {}

struct PackData {
    static let `default` = PackData(data: [:])

    var data: [DataType: [String: PackDataItem]] = [:]

    func getData<T: PackDataItem>(for type: DataType) -> [String: T] {
        return data[type] as? [String: T] ?? [:]
    }

    func merge(_ data: PackData) -> PackData {
        var result = self

        data.data.forEach { (key, value) in
            let selfData = result.data[key] ?? [:]
            result.data[key] = value.merging(selfData, uniquingKeysWith: { $1 })
        }

        return result
    }
}

extension Chat: PackDataItem {}
extension Chatter: PackDataItem {}
extension Message: PackDataItem {}
extension UrgentStatus: PackDataItem {}
extension Int32: PackDataItem {}

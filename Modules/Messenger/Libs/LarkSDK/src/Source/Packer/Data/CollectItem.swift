//
//  CollectItem.swift
//  Lark
//
//  Created by liuwanlin on 2018/6/11.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation

enum ExtraInfoKey: String {
    case chatId
}

struct CollectItem {
    static let `default` = CollectItem(data: [:])

    var data: [DataType: [String]]
    var extraInfo: [ExtraInfoKey: String]

    init(data: [DataType: [String]] = [:], extraInfo: [ExtraInfoKey: String] = [:]) {
        self.data = data
        self.extraInfo = extraInfo
    }

    func merge(_ item: CollectItem) -> CollectItem {
        var result = self

        item.data.forEach { (key, data) in
            let selfData = result.data[key] ?? []
            result.data[key] = data + selfData
        }
        if result.extraInfo.isEmpty {
            result.extraInfo = item.extraInfo
        }
        return result
    }

    func unique() -> CollectItem {
        var result = self
        result.data = result.data.mapValues({ (data) -> [String] in
            return data.lf_unique()
        })
        return result
    }
}

//
//  PackItem.swift
//  Lark
//
//  Created by liuwanlin on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation

class PackItem<T> {
    func collect(model: T) -> CollectItem {
        assertionFailure("must override")
        return .default
    }

    func pack(model: T, data: PackData) -> T {
        assertionFailure("must override")
        return model
    }
}

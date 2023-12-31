//
//  CollectionExtension.swift
//  ByteViewCommon
//
//  Created by fakegourmet on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public extension Collection {
    subscript(safeAccess index: Index) -> Element? {
        self.indices.contains(index) ? self[index] : nil
    }
}

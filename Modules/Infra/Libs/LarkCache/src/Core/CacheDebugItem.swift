//
//  CacheDebugItem.swift
//  LarkCache
//
//  Created by Supeng on 2020/11/2.
//

import UIKit
import Foundation
import LarkDebugExtensionPoint

public struct CacheDebugItem: DebugCellItem {
    public init() {}

    public let title = "下次进入后台开始自动清理缓存"

    /// Called when the corresponding cell is selected.
    public func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        KVStates.cleanRecord = nil
        KVStates.lastCleanTime = nil
    }
}

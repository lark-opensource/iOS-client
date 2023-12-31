//
//  ToolBarServiceProvider.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/2/24.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

protocol ToolBarServiceProvider: AnyObject {
    // ---- State ----
    func shrinkToolBar(from item: ToolBarItem, completion: (() -> Void)?)
    func expandToolBar(from item: ToolBarItem)

    // ---- Badge ----
    var badgeManager: ToolBarBadgeManager { get }

    // ---- Misc ----

    func generateImpactFeedback()

    func item(with type: ToolBarItemType) -> ToolBarItem
    func itemView(with type: ToolBarItemType) -> UIView?

    /// for route
    var hostViewController: UIViewController? { get }
}

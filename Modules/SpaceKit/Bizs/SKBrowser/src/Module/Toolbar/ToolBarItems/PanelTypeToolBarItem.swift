//
//  PanelTypeToolBarItem.swift
//  SpaceKit
//
//  Created by Webster on 2019/1/24.
//

import Foundation
import SKCommon
import SKInfra

class PanelTypeToolBarItem: DocsBaseToolBarItem {

    var childStatus: [BarButtonIdentifier: ToolBarItemInfo] = [BarButtonIdentifier: ToolBarItemInfo]()
    var buttonJsMethod: String?

    override var tapAgainToBack: Bool {
        return true
    }

    /// init
    ///
    /// - Parameter info: tool bar item info
    override init(info: ToolBarItemInfo, resolver: DocsResolver = DocsContainer.shared) {
        super.init(info: info, resolver: resolver)
        if let children = self.info().children {
            for child in children {
                if let identifier = BarButtonIdentifier(rawValue: child.identifier) {
                    childStatus.updateValue(child, forKey: identifier)
                }
            }
        }
    }

    /// bar item type
    ///
    /// - Returns: panel
    override func type() -> DocsToolBar.ItemType {
        return .panel
    }

}

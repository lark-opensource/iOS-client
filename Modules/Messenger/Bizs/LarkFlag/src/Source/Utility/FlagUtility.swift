//
//  FlagUtility.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkCore
import LarkSearchCore
import LarkOpenFeed
import LarkContainer

struct FlagUtility {
    static let maxCharCountAtOneLine: Int = 60

    static var imageMaxSize: CGSize {
        return CGSize(width: 120, height: 120)
    }

    static var imageMinSize: CGSize {
        return CGSize(width: 50, height: 50)
    }

    static var locationScreenShotSize: CGSize {
        let screen = UIScreen.main.bounds
        let width = min(270, screen.width * 279 / 375)
        let height = CGFloat(70.0)
        return CGSize(width: width, height: height)
    }

    static func getCellIdentifier(_ flagItem: FlagItem, feedCardModuleManager: FeedCardModuleManager?) -> String {
        var identifier: String = "UnknownTableCell"
        if let feedVM = flagItem.feedVM {
            if let feedCardModuleManager = feedCardModuleManager, let cellIdentifier = FeedCardContext.getFeedCardCellReuseId(feedCardModuleManager: feedCardModuleManager, viewModel: feedVM) {
                identifier = cellIdentifier
            }
        } else if let messageVM = flagItem.messageVM {
            identifier = messageVM.identifier
        }
        return identifier
    }
}

//
//  FeedDebug.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/5.
//

import Foundation
import LarkDebugExtensionPoint

struct FeedDebugItem: DebugCellItem {
    let title = "Feed调试"
    let type: DebugCellType = .switchButton

    var isSwitchButtonOn: Bool {
        return Feed.Feature.isDebugMode
    }

    var switchValueDidChange: ((Bool) -> Void)?

    init() {
        self.switchValueDidChange = { (isOn: Bool) in
            if isOn {
                Feed.Feature.isDebugMode = true
            } else {
                Feed.Feature.isDebugMode = false
            }

            NotificationCenter.default.post(name: FeedNotification.didChangeDebugMode,
                                            object: nil,
                                            userInfo: nil)
        }
    }
}

public final class FeedDebug {
    public static func executeTask(_ task: @escaping (() -> Void)) {
#if !LARK_NO_DEBUG
        if Feed.Feature.isDebugMode {
            task()
        }
#endif
    }
}

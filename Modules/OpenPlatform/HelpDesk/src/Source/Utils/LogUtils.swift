//
//  LogUtils.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/30.
//

import Foundation
import ECOProbe
import LKCommonsLogging

let openBannerLogger = Logger.oplog(BannerContainer.self, category: "HelpDeskOpenBanner")

func safeLogValue(_ value: String?) -> String {
    if let value = value {
        return "{md5:\(value.md5()), length:\(value.count)}"
    } else {
        return "nil"
    }
}

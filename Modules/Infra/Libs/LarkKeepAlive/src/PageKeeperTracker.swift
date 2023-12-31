//
//  PageKeeperTracker.swift
//  LarkKeepAlive
//
//  Created by Yaoguoguo on 2023/10/23.
//

import UIKit
import Foundation
import Homeric
import LKCommonsTracker
import LarkQuickLaunchInterface

final class PageKeeperTracker {
    class func trackBeginKeeplive(id: String,
                                  pageID: String,
                                  type: PageKeeperType,
                                  beginTime: TimeInterval,
                                  keepTime: TimeInterval,
                                  scene: PageKeeperScene, 
                                  isFull: Bool) {
        let params: [AnyHashable: Any] = [
            "keepliveID": id,
            "webBiz": type.rawValue,
            "webID": pageID,
            "keepliveBeginTime": beginTime,
            "keepliveTime": keepTime,
            "keepliveReason": scene.rawValue,
            "isKeepliveQueueFull": isFull
        ]
        Tracker.post(
            TeaEvent("lark_webapp_begin_keeplive", params: params)
        )
    }

    class func trackEndKeeplive(id: String,
                                pageID: String,
                                type: PageKeeperType,
                                endTime: TimeInterval,
                                endKeepliveReason: String,
                                keepliveEndDelayReason: String) {
        let params: [AnyHashable: Any] = [
            "keepliveID": id,
            "webBiz": type.rawValue,
            "webID": pageID,
            "keepliveEndTime": endTime,
            "endKeepliveReason": endKeepliveReason,
            "keepliveEndDelayReason": keepliveEndDelayReason
        ]
        Tracker.post(
            TeaEvent("lark_webapp_end_keeplive", params: params)
        )
    }
}

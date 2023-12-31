//
//  OneKeyLoginTrackService.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/6/11.
//

import Foundation
import BDUGContainer
import BDUGTrackerInterface
import BDUGMonitorInterface
import LKCommonsTracker

/// TTAccountSDK https://doc.bytedance.net/docs/177/266/15778/
class OneKeyLoginTrackService: NSObject, BDUGTrackerInterface, BDUGMonitorInterface {

    class func bind() {
        BDUGContainer.sharedInstance().setClass(OneKeyLoginTrackService.self, for: BDUGTrackerInterface.self) // user:checked (global-resolve)
        BDUGContainer.sharedInstance().setClass(OneKeyLoginTrackService.self, for: BDUGMonitorInterface.self) // user:checked (global-resolve)
    }

    func event(_ event: String, params: [AnyHashable: Any]?) {
        SuiteLoginTracker.track(event, params: params ?? [:])
    }

    func trackService(_ serviceName: String!, attributes: [AnyHashable: Any]! = [:]) {
        #if DEBUG
        print("OneKeyLogin monitor event:\(String(describing: serviceName)) params: \(String(describing: attributes))")
        #endif
    }
}

//
//  RustApiService.swift
//  Moment
//
//  Created by zhuheng on 2020/12/30.
//

import Foundation
import RxSwift
import LarkRustClient
import LKCommonsLogging
import LKCommonsTracker
import Swinject
import RustPB
import EEAtomic
import LarkContainer

final class RustApiService {

    static let logger = Logger.log(RustApiService.self, category: "Moment.RustApi")

    let client: RustService
    let userPushCenter: PushNotificationCenter

    init(client: RustService, userPushCenter: PushNotificationCenter) {
        self.client = client
        self.userPushCenter = userPushCenter
    }
}

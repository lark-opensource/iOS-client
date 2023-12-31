//
//  AppLauncherDelegate.swift
//  ByteViewDemo
//
//  Created by kiri on 2021/3/11.
//

import Foundation
import LarkAccountInterface
import BootManager
import ByteViewCommon

class DemoLauncherDelegate: PassportDelegate {
    let name = "ByteViewDemoLauncherDelegate"

    func userDidOnline(state: PassportState) {
        if let user = state.user {
            DemoCache.shared.accountId = user.userID
            Logger.demo.info("userDidOnline: \(user.userID)")
        }
    }
}

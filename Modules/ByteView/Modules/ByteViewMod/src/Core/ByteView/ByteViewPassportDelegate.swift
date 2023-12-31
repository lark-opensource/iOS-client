//
//  ByteViewPassportDelegate.swift
//  ByteViewMod
//
//  Created by kiri on 2021/9/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewInterface
import BootManager
import LarkAccountInterface
import UIKit
import LarkRustClient
import Heimdallr
import RustPB
import ByteViewTracker
import SnapKit
import LarkContainer
import LarkMedia

private typealias NoticeByteviewEventRequest = Videoconference_V1_NoticeByteviewEventRequest

final class ByteViewPassportDelegate: PassportDelegate {
    let name: String = "VideoConference"
    static let voipContextName = "ByteViewVoIP"
    static let shared = ByteViewPassportDelegate()

    private static let logger = Logger.account
    private static let privacyLogger = Logger.getLogger("Privacy")

    private init() {}

    func stateDidChange(state: PassportState) {
        Self.logger.info("PassportState did change, state = \(state)")
        if let userId = state.user?.userID, state.loginState == .online {
            self.login(userId)
        } else {
            self.logout()
        }
    }

    @RwAtomic private var currentUserId: String?
    @RwAtomic private var isFirstLogin = false
    private func login(_ userId: String) {
        if self.currentUserId == userId { return }
        self.currentUserId = userId
        if isFirstLogin {
            self.isFirstLogin = false
        } else {
            NotificationCenter.default.post(name: VCNotification.didChangeAccountNotification, object: self,
                                            userInfo: [VCNotification.userIdKey: userId])
        }
    }

    private func logout() {
        if self.currentUserId == nil { return }
        self.currentUserId = nil
        NotificationCenter.default.post(name: VCNotification.didChangeAccountNotification, object: self)
    }

    func onBootTask(userResolver: UserResolver) {
        let userId = userResolver.userID
        if self.currentUserId != userId {
            Self.logger.error("currentUserId did change in bootTask!!!")
            self.login(userId)
        }
        SnapKit.Dependency.setup(preventCrashDependency: SnapKitDependencyImpl(userResolver: userResolver))
    }
}

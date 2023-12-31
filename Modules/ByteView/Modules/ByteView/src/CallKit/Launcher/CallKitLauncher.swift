//
//  CallKitLauncher.swift
//  ByteView
//
//  Created by kiri on 2023/6/6.
//

import Foundation
import Intents

public final class CallKitLauncher {
    public static func setup(userId: String, factory: @escaping () throws -> MeetingDependency) {
        CallKitManager.shared.setup(userId: userId, factory: factory)
    }

    public static func destroy() {
        CallKitManager.shared.destroy()
    }

    /// - returns: meetingId
    public static func processPersonHandle(_ handle: INPersonHandle?, currentUserId: String?, shuldShowAlert: Bool = true) -> String? {
        CXHandleUtil.processPersonHandle(handle, currentUserId: currentUserId, shuldShowAlert: shuldShowAlert)
    }
}

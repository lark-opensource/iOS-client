//
//  ByteViewApp.swift
//  ByteView
//
//  Created by kiri on 2021/8/15.
//

import Foundation
import ByteViewCommon
import ByteViewTracker
import ByteViewNetwork
import SwiftProtobuf
import EEAtomic
import CoreTelephony
import QuartzCore
import NotificationUserInfo
import ByteViewMeeting
import LarkMedia

final class ByteViewApp {
    static let shared = ByteViewApp()

    @RwAtomic private var isInitialized: Bool = false
    /// 当前的accountId
    private var userId: String { AccountUpdater.shared.userId }

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeAccount(_:)), name: VCNotification.didChangeAccountNotification, object: nil)
    }

    @objc private func didChangeAccount(_ notification: Notification) {
        if let userId = notification.userInfo?[VCNotification.userIdKey] as? String, !userId.isEmpty {
            // do nothing, lazy loading for preload
        } else {
            if isInitialized {
                AccountUpdater.shared.updateIfNeeded(userId: "", reason: "logout")
            }
        }
    }

    /// 预加载，用于用户切换未完成时，有服务需要初始化VC模块的问题。
    /// - note: 未登录时无效。
    func preload(account: AccountInfo, reason: String, checkForeground: Bool = true) throws {
        let userId = account.userId
        if userId.isEmpty {
            throw PreloadError.invalidUser
        }
        if self.userId == userId { return }
        if !checkForeground || account.isForegroundUser {
            _preload(userId: userId, reason: reason)
        } else {
            startupIfNeeded(reason: reason)
            Logger.context.error("preload failed, isForegroundUser = false, userId = \(userId), reason = \(reason)")
            throw PreloadError.invalidUser
        }
    }

    private func _preload(userId: String, reason: String) {
        let startTime = CACurrentMediaTime()
        startWithAccount(userId: userId, reason: "preload.\(reason)")
        let duration = CACurrentMediaTime() - startTime
        Logger.context.info("preload success, userId = \(userId), reason = \(reason), duration = \(Util.formatTime(duration))")
    }

    private func startWithAccount(userId: String, reason: String) {
        startupIfNeeded(reason: reason)
        AccountUpdater.shared.updateIfNeeded(userId: userId, reason: reason)
    }

    private func startupIfNeeded(reason: String) {
        if isInitialized { return }
        isInitialized = true
        let startTime = CACurrentMediaTime()
        AppInfo.shared.setup()
        Logger.setup(LogInterceptor.shared)
        MeetingSession.setAdapter(VcMeetingAdapter.self, for: .vc)
        HttpClient.setupErrorHandler(NetworkErrorHandlerImpl.shared)
        let duration = CACurrentMediaTime() - startTime
        Queue.tracker.async {
            Logger.context.info("startup ByteViewApp, reason = \(reason), duration = \(Util.formatTime(duration))")
        }
    }
}

private class AccountUpdater {
    static let shared = AccountUpdater()
    private let lock = NSLock()
    private var isFirstLogin = true
    private var context: ByteViewContext?

    @RwAtomic
    private(set) var userId: String = ""

    func updateIfNeeded(userId: String, reason: String) {
        let oldValue = self.userId
        let newValue = userId
        if _userId.setIfChanged(newValue) {
            lock.lock()
            defer { lock.unlock() }

            // 清理上一个Context
            self.context = nil

            if newValue.isEmpty {
                Queue.logger.async {
                    Logger.context.info("logout, reason = \(reason), old accountId = \(oldValue)")
                }
            } else {
                let startTime = CACurrentMediaTime()
                // 创建下一个Context
                let context = ByteViewContext(userId: newValue)
                self.context = context
                let isFirst = self.isFirstLogin
                self.isFirstLogin = false
                let duration = CACurrentMediaTime() - startTime
                Queue.logger.async {
                    Logger.context.info("login, isFirst = \(isFirst), reason = \(reason), accountId = \(newValue), duration = \(Util.formatTime(duration))")
                }
            }
        } else {
            Queue.logger.async {
                Logger.context.info("account is not changed, from: \(reason), accountId = \(oldValue)")
            }
        }
    }
}

private class LogInterceptor: LogDelegate {
    static let shared = LogInterceptor()

    func didLog(on category: String) {
        SlardarLog.log(with: category)
    }
}

private enum PreloadError: String, Error, CustomStringConvertible {
    case invalidUser
    var description: String { "PreloadError.\(rawValue)" }
}

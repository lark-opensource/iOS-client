//
//  TerminationMonitor.swift
//  ByteView
//
//  Created by chentao on 2019/4/3.
//

import Foundation
import ByteViewCommon

public enum TerminationType: String, CustomStringConvertible {
    case unknown
    case userKilled
    case appCrashed
    case systemRecycled

    public var description: String { rawValue }
}

public final class TerminationMonitor {

    private static let logger = Logger.util

    private var _type: TerminationType = .unknown

    public convenience init(storage: LocalStorage) {
        self.init(storage.toStorage(UserStorageKey.self))
    }

    public var latestTerminationType: TerminationType {
        return _type
    }

    private let storage: UserStorage
    init(_ storage: UserStorage) {
        self.storage = storage
        /// 恢复上一次的数据
        self.recoverLastContext()
        /// 重置
        self.resetLocalContext()

        NotificationCenter.default.addObserver(self, selector: #selector(willTerminate),
                                               name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// 用户杀死 清除标识
    @objc private func willTerminate() {
        storage.set(true, forKey: .userKilled)
        TerminationMonitor.logger.info("user killed app")
    }

    /// 到后台
    @objc private func didEnterBackground() {
        storage.set(true, forKey: .appEnterBackground)
        storage.set(false, forKey: .appLaunch)
    }

    /// 回前台
    @objc private func willEnterForeground() {
        storage.set(false, forKey: .appEnterBackground)
        storage.set(true, forKey: .appLaunch)
    }

    private func recoverLastContext() {
        if isKilledByUser() {
            _type = .userKilled
        } else if isCrashed() {
            _type = .appCrashed
        } else if isSystemRecycled() {
            _type = .systemRecycled
        }
        TerminationMonitor.logger.info("last termination type is \(_type)")
    }

    private func resetLocalContext() {
        storage.set(false, forKey: .userKilled)
        storage.set(true, forKey: .appLaunch)
        storage.set(false, forKey: .appEnterBackground)
    }

    private func isKilledByUser() -> Bool {
        storage.bool(forKey: .userKilled, defaultValue: false)
    }

    private func isCrashed() -> Bool {
        storage.bool(forKey: .appLaunch, defaultValue: true)
    }

    private func isSystemRecycled() -> Bool {
        storage.bool(forKey: .appEnterBackground, defaultValue: false)
    }
}

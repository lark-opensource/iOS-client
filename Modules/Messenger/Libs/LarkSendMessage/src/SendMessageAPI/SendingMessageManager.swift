//
//  SendingMessageManager.swift
//  LarkSendMessage
//
//  Created by 李勇 on 2023/1/16.
//

import UIKit
import Foundation
import LKCommonsLogging // Logger
import ThreadSafeDataStructure // SafeSet

public protocol SendingMessageManager {
    func add(task: String)
    func remove(task: String)
}

/// 判断当前是否还有消息未发送完，进入后台时创建BackgroundTask，短时间内还能继续发送
final class SendingMessageManagerImpl: SendingMessageManager {

    private static let logger = Logger.log(SendingMessageManagerImpl.self, category: "RustSDK.SendMessage")

    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    private var sendingSet: SafeSet<String> = SafeSet<String>([], synchronization: .semaphore)

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActiveNotification), name: UIApplication.willResignActiveNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func add(task: String) {
        sendingSet.insert(task)
    }

    public func remove(task: String) {
        sendingSet.remove(task)

        if sendingSet.isEmpty, self.backgroundTaskID != .invalid {
            // 延时两秒判断是否需要结束后台任务
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.checkBackgroundEnd()
            }
        }
    }

    private func checkBackgroundEnd() {
        Self.logger.info("check background task end")
        if sendingSet.isEmpty, self.backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
            self.backgroundTaskID = .invalid
            Self.logger.info("end background task")
        }
    }

    @objc
    private func willResignActiveNotification() {
        guard !self.sendingSet.isEmpty else { return }

        Self.logger.info("sending message began background task")
        self.backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "SendMessage", expirationHandler: { [weak self] in
            guard let self = self else { return }
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
            self.backgroundTaskID = .invalid
            Self.logger.info("sending message time out")
        })
    }

    @objc
    private func didBecomeActiveNotification() {
        if self.backgroundTaskID != .invalid {
            Self.logger.info("sending message end background task")
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
            self.backgroundTaskID = .invalid
        }
    }
}

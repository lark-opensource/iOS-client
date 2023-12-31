//
//  CaptureDispatcher.swift
//  EETroubleKiller
//
//  Created by lixiaorui on 2019/5/13.
//

import UIKit
import Foundation

protocol CaptureDispatcherDelegate: AnyObject {

    func triggerLog(_ type: CaptureType, tracingId: String)

}

final class CaptureDispatcher {

    private struct RecordConfig {
        var count: Int = 0
        var tracingId: String = ""
    }

    private var recordConfig = RecordConfig()

    weak var delegate: CaptureDispatcherDelegate?

    private var logTimer: Timer?

    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(screenShot),
                                               name: UIApplication.userDidTakeScreenshotNotification,
                                               object: nil)
        if #available(iOS 11.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(screenRecord),
                                                   name: UIScreen.capturedDidChangeNotification,
                                                   object: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterForeground),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func startContinousLog() {
        recordConfig.count = 0
        recordConfig.tracingId = UUID().uuidString
        enableTimer()
    }

    private func stopContinousLog() {
        disableTimer()
    }

    @objc
    private func triggerRecordLog() {
        recordConfig.count += 1
        guard recordConfig.count < TroubleKiller.config.recordLimit else {
            stopContinousLog()
            return
        }
        delegate?.triggerLog(.record, tracingId: "\(recordConfig.tracingId)-\(recordConfig.count)")
    }

    private func enableTimer() {
        guard logTimer == nil else { return }
        logTimer = Timer(timeInterval: TimeInterval(TroubleKiller.config.recordInterval),
                         target: self, selector: #selector(triggerRecordLog),
                         userInfo: nil, repeats: true)
        RunLoop.main.add(logTimer!, forMode: .common)
        logTimer?.fire()
    }

    private func disableTimer() {
        logTimer?.invalidate()
        logTimer = nil
    }
}

// MARK: - Notifications
extension CaptureDispatcher {

    @objc
    private func screenShot() {
        TroubleKiller.logger.debug("screen shot. enabled: \(TroubleKiller.config.enable)", tag: LogTag.log)
        guard TroubleKiller.config.enable, case .active = UIApplication.shared.applicationState else { return }
        delegate?.triggerLog(.shot, tracingId: UUID().uuidString)
    }

    @objc
    private func screenRecord(_ noti: Notification) {
        TroubleKiller.logger.debug("screen record. enabled: \(TroubleKiller.config.enable)", tag: LogTag.log)
        guard #available(iOS 11.0, *), TroubleKiller.config.enable, let screen = noti.object as? UIScreen else { return }
        if screen.isCaptured && recordConfig.count < TroubleKiller.config.recordLimit {
            startContinousLog()
        } else {
            stopContinousLog()
        }
    }

    @objc
    private func appDidEnterForeground() {
        guard #available(iOS 11.0, *), TroubleKiller.config.enable else { return }
        if UIScreen.main.isCaptured {
            startContinousLog()
        } else {
            stopContinousLog()
        }
    }

    @objc
    private func appDidEnterBackground() {
        guard TroubleKiller.config.enable else { return }
        stopContinousLog()
    }

}

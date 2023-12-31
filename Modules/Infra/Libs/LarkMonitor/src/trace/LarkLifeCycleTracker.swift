//
//  LarkLifeCycleTracker.swift
//  LarkMonitor
//
//  Created by sniperj on 2020/11/22.
//

import UIKit
import Foundation

public final class LarkLifeCycleTracker: NSObject {

    static let shared: LarkLifeCycleTracker = LarkLifeCycleTracker()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    public class func startTrackUI() {
        let tracker = LarkLifeCycleTracker.shared
        tracker.observeMenuViewController()
    }

    // MARK: - UIMenuController
    private func observeMenuViewController() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTerminate(noti:)),
            name: UIApplication.willTerminateNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEnterForeground(noti:)),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEnterBackground(noti:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc
    func handleTerminate(noti: NSNotification) {
        LarkAllActionLoggerLoad.logLifeCycleInfo(info: "app enterTerminate")
    }

    @objc
    func handleEnterForeground(noti: NSNotification) {
        LarkAllActionLoggerLoad.logLifeCycleInfo(info: "app enterForeground")
    }

    @objc
    func handleEnterBackground(noti: NSNotification) {
        LarkAllActionLoggerLoad.logLifeCycleInfo(info: "app enterBackground")
    }
}

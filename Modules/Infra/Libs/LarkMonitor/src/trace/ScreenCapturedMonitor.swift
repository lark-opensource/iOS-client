//
//  ScreenCapturedMonitor.swift
//  LarkMonitor
//
//  Created by zhaojiachen on 2021/8/23.
//

import Foundation
import LKCommonsTracker
import Homeric
import UIKit
import EENavigator
import BootManager

final class ScreenCapturedMonitor {
    static func setup() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(Self.screenCapturedDidChange(_:)),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
    }

    @objc
    static func screenCapturedDidChange(_ notification: Notification) {
        guard let screen = notification.object as? UIScreen,
              screen.isCaptured else { return }
        let topClassName = getDemangledTopVC()
        Tracker.post(TeaEvent(
            Homeric.PUBLIC_SCREEN_RECORDING_CLICK,
            params: [
                "click": "screen_recording",
                "target": "none",
                "start_recording_view": topClassName
            ]
        ))
        ScreenMonitorHelper.auditEvent(currentPage: topClassName, eventType: .screenRecording)
    }

    private static func getDemangledTopVC() -> String {
        guard let topMost = Navigator.shared.mainSceneTopMost else { //Global
            return ""
        }
        return topMost.tkClassName
    }
}

final class ScreenCapturedMonitorLaunchTask: FlowBootTask, Identifiable { //Global
    static var identify = "ScreenCapturedMonitorLaunchTask"

    override var runOnlyOnce: Bool {
        return true
    }

    override func execute(_ context: BootContext) {
        ScreenCapturedMonitor.setup()
    }
}

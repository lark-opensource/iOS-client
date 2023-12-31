//
//  AudioSuspendable.swift
//  Minutes
//
//  Created by admin on 2021/4/1.
//

import UIKit
import Foundation
import LarkUIKit
import LarkSuspendable
import MinutesFoundation

class AudioSuspendable {
    static let suspendViewKey: String = "com.minutes.record.suspend"

    static func addRecordSuspendable(customView: UIView, size: CGSize) {
        MinutesLogger.record.info("addRecordSuspendable")

        if isExistRecordSuspendable() {
            removeRecordSuspendableView()
        } else {
            InnoPerfMonitor.shared.update(floating: true)
        }

        if SuspendManager.isFloatingEnabled {
            SuspendManager.shared.addCustomView(customView, size: size, forKey: AudioSuspendable.suspendViewKey, level: .middle + 1)
        }
    }

    static func removeRecordSuspendableView() {
        MinutesLogger.record.info("removeRecordSuspendableView")
        if SuspendManager.shared.customView(forKey: AudioSuspendable.suspendViewKey) != nil {
            SuspendManager.shared.removeCustomView(forKey: AudioSuspendable.suspendViewKey)
        }
    }

    public static func removeRecordSuspendable() {
        MinutesLogger.record.info("removeRecordSuspendable")
        guard isExistRecordSuspendable() else { return }
        InnoPerfMonitor.shared.update(floating: false)
        removeRecordSuspendableView()
    }

    public static func isExistRecordSuspendable() -> Bool {
        let systemView = SuspendManager.shared.customView(forKey: AudioSuspendable.suspendViewKey)
        return systemView != nil 
    }
}

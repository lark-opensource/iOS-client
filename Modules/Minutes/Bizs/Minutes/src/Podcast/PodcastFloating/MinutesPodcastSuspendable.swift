//
//  MinutesPodcastSuspendable.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/4/6.
//

import UIKit
import Foundation
import LarkUIKit
import LarkSuspendable
import MinutesFoundation

public final class MinutesPodcastSuspendable {
    static let suspendViewKey: String = "com.minutes.podcast.suspend"

    static func addPodcastSuspendable(customView: UIView, size: CGSize) {

        if isExistPodcastSuspendable() {
            removePodcastSuspendableView()
        } else {
            InnoPerfMonitor.shared.update(floating: true)
        }

        if Display.phone {
            if SuspendManager.isFloatingEnabled {
                SuspendManager.shared.addCustomView(customView, size: size,
                                                    forKey: MinutesPodcastSuspendable.suspendViewKey,
                                                    level: .middle - 1)
            }
        }
    }

    static func removePodcastSuspendableView() {
        if SuspendManager.shared.customView(forKey: MinutesPodcastSuspendable.suspendViewKey) != nil {
            SuspendManager.shared.removeCustomView(forKey: MinutesPodcastSuspendable.suspendViewKey)
        }
    }

    public static func removePodcastSuspendable() {
        guard isExistPodcastSuspendable() else { return }
        InnoPerfMonitor.shared.update(floating: false)
        removePodcastSuspendableView()
    }

    public static func isExistPodcastSuspendable() -> Bool {
        let systemView = SuspendManager.shared.customView(forKey: MinutesPodcastSuspendable.suspendViewKey)
        return systemView != nil
    }

    public static func currentPlayer() -> MinutesVideoPlayer? {
        let systemView = SuspendManager.shared.customView(forKey: MinutesPodcastSuspendable.suspendViewKey) as? MinutesPodcastFloatingView
        return systemView?.videoPlayer
    }
}

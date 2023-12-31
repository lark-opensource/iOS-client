//
//  FocusStatus+Common.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/12/28.
//

import UIKit
import Foundation
import Metal
import LarkEmotion
import LarkFocusInterface

public extension FocusStatus {

    var isActive: Bool {
        return effectiveInterval.isActive
    }

    /// 几种默认状态的 icon 资源兜底
    var defaultIcon: UIImage? {
        switch iconKey {
        case "GeneralDoNotDisturb":
            return BundleResources.LarkFocus.default_icon_not_disturb
        case "GeneralInMeetingBusy":
            return BundleResources.LarkFocus.default_icon_in_meeting
        case "Coffee":
            return BundleResources.LarkFocus.default_icon_rest
        default:
            return EmotionResouce.placeholder
        }
    }
}

public extension Array where Element: FocusStatus {

    var topActive: Element? {
        self.filter({ $0.isActive }).first
    }
}

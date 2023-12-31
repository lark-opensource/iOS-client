//
//  LkWindowManager+Config.swift
//  LKWindowManager
//
//  Created by Yaoguoguo on 2022/12/14.
//

import UIKit
import Foundation

public enum LKWindowKey: String {
    case none
    case LKWindowNormal = "LKWindow.Normal"
    case LKWindowAlert = "LKWindow.Alert"
    case PushCardWindow
    case UrgencyWindow
}

public let windowConfigMap: [LKWindowKey: LKWindowConfig] = [.LKWindowNormal: LKWindowConfig(.LKWindowNormal,
                                                                                             level: .normal,
                                                                                             virtuals: []),
                                                             .LKWindowAlert: LKWindowConfig(.LKWindowAlert,
                                                                                            level: .normal,
                                                                                            virtuals: [VirtualWindowConfig(.PushCardWindow, level: .alert + 50),
                                                                                                       VirtualWindowConfig(.UrgencyWindow, level: .alert + 100)])]

public struct LKWindowConfig {
    public let identifier: LKWindowKey

    public let level: UIWindow.Level

    public var virtuals: [LKWindowKey: VirtualWindowConfig] = [:]

    public init(_ identifier: LKWindowKey,
                level: UIWindow.Level,
                virtuals: [VirtualWindowConfig] = []) {
        self.identifier = identifier
        self.level = level
        virtuals.forEach { config in
            self.virtuals[config.identifier] = config
        }
    }
}

public struct VirtualWindowConfig {
    public let identifier: LKWindowKey

    public let level: UIWindow.Level

    public init(_ identifier: LKWindowKey, level: UIWindow.Level) {
        self.identifier = identifier
        self.level = level
    }
}

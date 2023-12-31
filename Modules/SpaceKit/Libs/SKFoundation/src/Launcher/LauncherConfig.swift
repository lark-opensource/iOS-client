//
//  LauncherConfig.swift
//  Launcher
//
//  Created by nine on 2020/1/9.
//  Copyright © 2020 nine. All rights reserved.
//

import Foundation

public typealias LauncherSystemStateValue = Double
public enum LauncherSystemStateKey: String {
    case cpu
}

public final class LauncherConfig {
    public var leisureCondition: [LauncherSystemStateKey: LauncherSystemStateValue]
    public var leisureTimes: Int
    public var monitorInterval: TimeInterval

    public init(leisureCondition: [LauncherSystemStateKey: LauncherSystemStateValue] = [LauncherSystemStateKey: LauncherSystemStateValue](),
         monitorInterval: TimeInterval = 1.0,
         leisureTimes: Int = 3) {
        self.leisureCondition = leisureCondition
        self.leisureTimes = leisureTimes
        self.monitorInterval = monitorInterval
    }
}

//
//  UDTracker.swift
//  LarkFontAssembly
//
//  Created by 白镜吾 on 2023/9/8.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTheme
import LKCommonsLogging
import LKCommonsTracker

class UDTracker: UDTrackerDependency {
    static var logger = Logger.log(UDTracker.self)

    private let iconTracker = "icon_tracker"

    func logger(component: UDComponentType, loggerType: UDLoggerType, msg: String) {
        let logMsg = component.rawValue + ": " + msg
        switch loggerType {
        case .error:
            UDTracker.logger.error(logMsg)
        case .info:
            UDTracker.logger.info(logMsg)
        }
    }

    func getIconFailTracker(iconName: String?) {
        Tracker.post(SlardarEvent(name: iconTracker,
                                  metric: [:],
                                  category: [
                                    "icon_name": iconName ?? "icon_placeHolder"
                                  ],
                                  extra: [:]))
    }
}

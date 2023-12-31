//
//  InMeetMagicShareManagerDefines.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/12/20.
//

import Foundation
import ByteViewSetting

extension InMeetFollowManager {
    var isMagicShareDowngradeEnabled: Bool {
        meeting.setting.isMagicShareDowngradeEnabled
    }
    var isMagicShareDowngradeConfigEnabled: Bool {
        downgradeConfig.degradeEnabled
    }
    var degradeSystemLoad: CGFloat {
        downgradeConfig.degradeSystemLoad
    }
    var degradeDynamicHighCount: Int {
        downgradeConfig.degradeDynamicHighCount
    }
    var degradeDynamicLowCount: Int {
        downgradeConfig.degradeDynamicLowCount
    }
    var degradeDynamicStep: CGFloat {
        downgradeConfig.degradeDynamicStep
    }
    var degradeDynamicMax: CGFloat {
        downgradeConfig.degradeDynamicMax
    }
    var degradeThermalFair: CGFloat {
        downgradeConfig.degradeThermalFair
    }
    var degradeThermalSerious: CGFloat {
        downgradeConfig.degradeThermalSerious
    }
    var degradeThermalCritical: CGFloat {
        downgradeConfig.degradeThermalCritical
    }
    var degradeOpenDocStep: CGFloat {
        downgradeConfig.degradeOpenDocStep
    }
    var degradeOpenDocInterval: CGFloat {
        downgradeConfig.degradeOpenDocInterval
    }
    private var downgradeConfig: MagicShareDowngradeConfig {
        meeting.setting.magicShareDowngradeConfig
    }
}

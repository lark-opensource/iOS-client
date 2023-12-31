//
//  LaunchGuidePassportDependency.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2020/10/28.
//

import Foundation
import LarkAccountInterface

class LaunchGuidePassportDependencyImpl: LaunchGuidePassportDependency {
    var enableJoinMeeting: Bool {
        return PassportSwitch.shared.enableJoinMetting
    }
}

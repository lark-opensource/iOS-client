//
//  LarkLaunchGuideConfig.swift
//  LarkLaunchGuide
//
//  Created by quyiming on 2020/3/16.
//

import Foundation
import LKLaunchGuide
import LarkContainer
import LKCommonsTracker
import Homeric
import EENavigator
import LarkAccountInterface
import LarkAccount

typealias I18N = BundleI18n.LarkLaunchGuide

final class LarkLaunchGuideConfig: LaunchGuideConfigProtocol, LaunchGuideDelegate {

    @Provider var passportDependency: LaunchGuidePassportDependency

    var delegate: LaunchGuideDelegate? { self }

    func launchGuideDidShowPage(index: Int) {
        passportDependency.ugTrack("show_launch_page", eventParams: ["index": index])
    }

}

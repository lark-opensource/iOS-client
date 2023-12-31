//
//  Tracker.swift
//  LarkLaunchGuide
//
//  Created by Miaoqi Wang on 2019/5/23.
//

import Foundation
import Homeric
import LKCommonsTracker

typealias CommonsTracker = LKCommonsTracker.Tracker

final class Tracker {

    static func trackGuideShow(index: Int) {
        CommonsTracker.post(TeaEvent(Homeric.GUIDE_CAROUSEL_VIEW, params: ["slide_number": index]))
    }

    static func trackCreateTeamClick(index: Int) {
        CommonsTracker.post(TeaEvent(Homeric.GUIDE_CAROUSEL_CREATE_TEAM, params: ["slide_number": index]))
    }

    static func trackSignInClick(index: Int) {
        CommonsTracker.post(TeaEvent(Homeric.GUIDE_CAROUSEL_SIGN_IN, params: ["slide_number": index]))
    }

    static func trackV3LoginGuidePage() {
        CommonsTracker.post(TeaEvent(Homeric.LOGIN_GUIDE_PAGE))
    }

    static func trackV3EnterGuidePage() {
        CommonsTracker.post(TeaEvent(Homeric.ENTER_GUIDE_PAGE))
    }

    static func trackV3RegisterGuidePage() {
        CommonsTracker.post(TeaEvent(Homeric.REGISTER_GUIDE_PAGE))
    }
}

//
//  V3InputCrendentialTrackProtocol.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/3/12.
//

import Foundation
import Homeric

enum IDPLoginType {
    case unknown
    case sso
    case google
    case appleID
}

protocol V3InputCrendentialTrackProtocol {

    var service: V3LoginService { get }

    func trackClickNext()

    func trackSwitchMethod()

    func trackSwitchRegionCode()

    func trackClickServiceTerm(_ URL: URL)

    func trackClickPrivacy(_ URL: URL)

    func trackClickToRegister()

    func trackClickJionTeam()

    func trackSwitchCountryCode()

    func trackPrivacyCheckboxCheck(method: SuiteLoginMethod)

    func trackPrivacyCheckboxUnCheck(method: SuiteLoginMethod)

    func trackClickBack()

    func trackClickIDPLogin(_ type: IDPLoginType)

    func trackClickLocaleButton()

    func trackViewShow()

    func trackClickJoinMeeting(_ process: Process)
}

extension V3InputCrendentialTrackProtocol {
    func trackClickToRegister() {}

    func trackPrivacyCheckboxCheck(method: SuiteLoginMethod) {
        let methodStr = (method == .phoneNumber) ? "phone" : "email"
        let data = ["type": methodStr]
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: "", click: TrackConst.passportClickTrackCheckedPrivacyPolicy, target: "none", data: data)
        SuiteLoginTracker.track(Homeric.PASSPORT_LOGIN_CLICK, params: params)
    }

    func trackPrivacyCheckboxUnCheck(method: SuiteLoginMethod) {
        let methodStr = (method == .phoneNumber) ? "phone" : "email"
        let data = ["type": methodStr]
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: "", click: TrackConst.passportClickTrackCancelPrivacyPolicy, target: "none", data: data)
        SuiteLoginTracker.track(Homeric.PASSPORT_LOGIN_CLICK, params: params)
    }

    func trackClickBack() {}

    func trackClickIDPLogin(_ type: IDPLoginType) {
        SuiteLoginTracker.track(Homeric.IDP_LOGIN_BUTTON)
    }

    func trackClickJoinMeeting(_ process: Process) {
        let path: String
        switch process {
        case .login:
            path = TrackConst.pathLoginPageJoinMeeting
        case .register:
            path = TrackConst.pathRegisterPageJoinMeeting
        default:
            path = TrackConst.defaultPath
        }
        SuiteLoginTracker.track(
            Homeric.PASSPORT_CLICK_JOIN_MEETING,
            params: [
                TrackConst.path: path
            ])
    }
}

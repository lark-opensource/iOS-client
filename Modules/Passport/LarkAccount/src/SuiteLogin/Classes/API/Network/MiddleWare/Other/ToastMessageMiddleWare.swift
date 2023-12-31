//
//  ToastMessageMiddleWare.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/8/20.
//

import Foundation
import RoundedHUD
import LKCommonsLogging
import EENavigator

class ToastMessageMiddleWare: HTTPMiddlewareProtocol {
    static let logger = Logger.plog(ToastMessageMiddleWare.self, category: "SuiteLogin.ToastMessageMiddleWare")

    let helper: V3APIHelper

    init(helper: V3APIHelper) {
        self.helper = helper
    }

    func config() -> HTTPMiddlewareConfig {
        [
            .response: .low
        ]
    }

    func handle<ResponseData: ResponseV3>(
        request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void
    ) {
        if let stepResponse = request.response.resp as? V3.Step,
            let message = stepResponse.stepData.displayMsg,
            !message.isEmpty {
            guard let mainSceneWindow = PassportNavigator.keyWindow else {
                Self.logger.errorWithAssertion("no main scene for ToastMessageMiddleWare")
                return
            }

            DispatchQueue.main.async {
                RoundedHUD.showTips(with: message, on: mainSceneWindow)
            }
        }
        complete()
    }
}

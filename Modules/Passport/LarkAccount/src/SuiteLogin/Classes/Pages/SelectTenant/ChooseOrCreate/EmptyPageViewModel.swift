//
//  EmptyPageViewModel.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/7/26.
//

import Foundation
import LKCommonsLogging

class EmptyPageViewModel: V3ViewModel {
    let logger = Logger.plog(EmptyPageViewModel.self, category: "SuiteLogin.EmptyPageViewModel")

    let showPageInfo: ShowPageInfo

    init(
        step: String,
        showPageInfo: ShowPageInfo,
        context: UniContextProtocol
    ) {
        self.showPageInfo = showPageInfo
        super.init(step: step, stepInfo: showPageInfo, context: context)
    }

    func onButtonTap() {
        Self.logger.info("n_action_empty_page_button_tap")

        guard let buttonStepInfo = showPageInfo.buttonList.first?.next,
              let event = buttonStepInfo.stepName,
              let stepInfo = buttonStepInfo.stepInfo else {
            Self.logger.error("n_action_empty_page_button_invalid_step_info")
            return
        }

        LoginPassportEventBus.shared.post(event: event, context: V3RawLoginContext(stepInfo: stepInfo, context: context)) {
            Self.logger.info("n_action_empty_page_button_step_succ")
        } error: { error in
            Self.logger.error("n_action_empty_page_button_step_fail", error: error)
        }
    }
}

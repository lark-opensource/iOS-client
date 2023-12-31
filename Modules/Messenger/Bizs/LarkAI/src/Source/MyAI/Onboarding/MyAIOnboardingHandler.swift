//
//  MyAIOnboardingHandler.swift
//  LarkAI
//
//  Created by ByteDance on 2023/5/11.
//

import Foundation
import LarkMessengerInterface
import EENavigator
import LarkNavigator
import LarkContainer
import LarkUIKit

/// 跳转自己的MyAI
final class MyAIOnboardingHandler: UserTypedRouterHandler {
    func handle(_ body: MyAIOnboardingBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let viewModel = MyAIOnboardingViewModel(userResolver: self.userResolver)
        // 绑定回调
        viewModel.successCallback = body.onSuccess
        viewModel.failureCallback = body.onError
        viewModel.cancelCallback = body.onCancel

        let onboardingVC = MyAIOnboardingInitController(viewModel: viewModel)
        let naviVC = LkNavigationController(rootViewController: onboardingVC)
        // iPad 上 Onboarding 页面大小
        naviVC.preferredContentSize = AICons.iPadModalSize
        naviVC.modalPresentationStyle = .formSheet
        if #available(iOS 13.0, *) {
            // 禁止 Onboarding 页面的下拉关闭
            naviVC.isModalInPresentation = true
        }
        res.end(resource: naviVC)
    }
}

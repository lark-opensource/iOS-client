//
//  SwitchUserSwitchIdentityAutoSwitchTask.swift
//  LarkAccount
//
//  Created by bytedance on 2021/10/3.
//

import Foundation
import LarkUIKit
import EENavigator
import RxSwift
import LarkAccountInterface

/// handle 需要验证的 switchIdentity 场景; 目前用于自动切换
/// 监听页面的堆栈,  如果后续页面返回或者取消的时候吗, cancel 掉当前的切换流程
class SwitchUserSwitchIdentityAutoSwitchTask: SwitchUserSwitchIdentityBaseTask {

    /// context from 需要设置为 switchUser.
    override var context: UniContextProtocol {
        var _contex = UniContextCreator.create(.continueSwitch)
        return _contex
    }

    override func handleV3StepInfo(_ stepInfo: V3.Step) {
        logger.info(SULogKey.switchCommon, body: "switch identity auto task handle next step")

        LoginPassportEventBus.shared.post(
            event: stepInfo.stepData.nextStep,
            context: V3RawLoginContext(
                stepInfo: stepInfo.stepData.stepInfo,
                vcHandler: {[weak self] (result) in
                    guard let self = self else { return }
                    if let vc = result {
                        self.handleNextStepVC(vc)
                    } else {
                        self.logger.error(SULogKey.switchCommon, body: "switch identity task fail with no viewController to present")
                        self.failCallback(AccountError.switchUserVerifyCancel)
                    }
                },
                context: context
            ),
            success: {}, error: {[weak self] error in
                guard let self = self else { return }
                self.logger.error(SULogKey.switchCommon, body: "switch identity task fail", error: error)

                self.failCallback(error)
            })
    }

    private func handleNextStepVC(_ vc: UIViewController) {
        logger.info(SULogKey.switchCommon, body: "switch identity auto switch task handle next step")

        guard let mainSceneTopMost = PassportNavigator.topMostVC else {
            logger.info(SULogKey.switchCommon, body: "switch identity auto switch task cancel with no topMost")
            ///如果没有找到最上层的 VC, 直接取消当前的切换流程
            failCallback(AccountError.switchUserVerifyCancel)
            assertionFailure("something wrong, please contact passport")
            return
        }

        let dismissSignalVC = SwitchUserLoadingViewController {[weak self] in
            guard let self = self else { return }
            self.logger.info(SULogKey.switchCommon, body: "switch identity auto switch task fail with dismiss signal")
            self.failCallback(AccountError.switchUserVerifyCancel)
        }

        let nav = LoginNaviController(rootViewController: dismissSignalVC)
        nav.pushViewController(vc, animated: false)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        mainSceneTopMost.present(nav, animated: true, completion: nil)

        logger.info(SULogKey.switchCommon, body: "switch identity auto switch task presented")

        switchContext.continueSwitchBlock = {[weak self] (enterAppInfo) in
            guard let self = self else { return }
            self.logger.info(SULogKey.switchCommon, body: "switch identity auto switch task continue with enterAppInfo")

            self.handleEnterAppInfo(enterAppInfo)
        }
    }
}

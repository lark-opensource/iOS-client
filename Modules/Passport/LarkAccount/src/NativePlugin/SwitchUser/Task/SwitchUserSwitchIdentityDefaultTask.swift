//
//  SwitchUserSwitchIdentityDefaultTask.swift
//  LarkAccount
//
//  Created by bytedance on 2021/10/3.
//

import Foundation
import LarkUIKit
import EENavigator
import LKCommonsLogging
import LarkAccountInterface

class SwitchUserSwitchIdentityDefaultTask: SwitchUserSwitchIdentityBaseTask {

    override func handleV3StepInfo(_ stepInfo: V3.Step) {

        logger.info(SULogKey.switchCommon, body: "switch identity default task handle next step")
        logger.info(SULogKey.switchCommon, body: "switch identity default task fail with need verify")
        //结束 task
        failCallback(AccountError.switchUserNeedVerify(nextStep: stepInfo.stepData.nextStep))
        //post step
        LoginPassportEventBus.shared.post(
            event: stepInfo.stepData.nextStep,
            context: V3RawLoginContext(
                stepInfo: stepInfo.stepData.stepInfo,
                vcHandler: { [weak self] (viewController) in
                    //此处需要用类方法处理, 因为上面 failCallback 之后, task 对象已经消失, 实例方法无法再 handle
                    if let vc = viewController {
                        Self.handleNextStepVC(vc)
                    } else {
                        self?.logger.error(SULogKey.switchCommon, body: "switch identity task fail with no viewController to present")
                    }
                },
                context: context
            ),
            success: {}, error: { _ in })
    }

    static let staticLogger = Logger.plog(SwitchUserSwitchIdentityDefaultTask.self, category: "NewSwitchUserService")
    static func handleNextStepVC(_ vc: UIViewController) {
        staticLogger.info(SULogKey.switchCommon, body: "switch identity default task handle next step")

        guard let mainSceneTopMost = PassportNavigator.topMostVC else {
            staticLogger.info(SULogKey.switchCommon, body: "switch identity default task cancel with no topMost")
            assertionFailure("something wrong, please contact passport")
            return
        }

        if let loginNavVC = mainSceneTopMost.navigationController as? LoginNaviController {
            loginNavVC.pushViewController(vc, animated: true)
        } else {
            presentVC(container: mainSceneTopMost, vc: vc)
        }
    }

    static func presentVC(container: UIViewController, vc: UIViewController) {
        let nav = LoginNaviController(rootViewController: vc)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        container.present(nav, animated: true, completion: nil)
    }
}

class SwitchUserSwitchIdentityAfterCrossEnvTask: SwitchUserSwitchIdentityDefaultTask {

    override var taskFrom: SUSwitchIdentityTaskFrom {
        .crossEnv
    }

    override func run() {
        logger.info(SULogKey.switchCommon, body: "switch identity after cross env task run", method: .local)

        guard let switchToUser = switchContext.switchUserInfo else {
            logger.error(SULogKey.switchCommon, body: "switch identity after cross env task fail with no target userInfo")
            self.failCallback(AccountError.notFoundTargetUser)
            assertionFailure("Something wrong, please contact passport")
            return
        }

        guard switchToUser.isAnonymous == true else {
            logger.info(SULogKey.switchCommon, body: "switch identity after cross env task succ", method: .local)
            succCallback()
            return
        }
        logger.info(SULogKey.switchCommon, body: "switch identity after cross env task call super")
        super.run()
    }
}

class SwitchUserSwitchIdentityAfterCrossEnvTaskV2: SwitchUserSwitchIdentityAfterCrossEnvTask {

   override func handleEnterAppInfo(_ enterAppInfo: V4EnterAppInfo) {
        ///如果这一次switch_identity接口获取的用户还是匿名的话，报错
        guard let remoteUser = enterAppInfo.userList.first,
              remoteUser.userID == switchContext.switchUserID,
              remoteUser.isActive else {
            failCallback(AccountError.switchUserCrossEnvFailed)
            return
        }
        super.handleEnterAppInfo(enterAppInfo)
    }
}

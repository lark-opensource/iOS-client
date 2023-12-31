//
//  GuideDialogAlertHandler.swift
//  LarkAccount
//
//  Created by au on 2023/5/18.
//

import Foundation
import LarkAccountInterface
import LarkContainer
import LKCommonsLogging
import UniverseDesignDialog
import UniverseDesignActionPanel

final class GuideDialogAlertHandler: GuideDialogHandlerProtocol {

    @Provider var passportService: PassportService
    private static let logger = Logger.log(GuideDialogAlertHandler.self, category: "LarkAccount")

    func handle(info: GuideDialogStepInfo,
                context: UniContextProtocol,
                vcHandler: EventBusVCHandler?,
                success: @escaping EventBusSuccessHandler,
                failure: @escaping EventBusErrorHandler) {
        guard let topVC = PassportNavigator.topMostVC else {
            Self.logger.error("n_action_guide_dialog_alert_no_vc")
            success()
            return
        }

        let action = { (buttonInfo: V4ShowDialogStepInfo.ActionBtn) in
            guard let nextStep = buttonInfo.nextStep else {
                if buttonInfo.actionType == .gotIt {
                    Self.logger.info("n_action_guide_dialog_alert: got it to logout")
                    // 风险场景下的登出
                    self.logout()
                    return
                }
                Self.logger.error("n_action_guide_dialog_alert: no_step")
                return
            }

            let postEventBus = {
                LoginPassportEventBus.shared.post(
                    event: nextStep.event,
                    context: V3RawLoginContext(
                        stepInfo: nextStep.info,
                        additionalInfo: ["presentWebURL": true],
                        vcHandler: vcHandler,
                        backFirst: nil,
                        context: context
                    ),
                    success: {
                        success()
                    }, error: { error in
                        failure(error)
                    }
                )
            }

            Self.logger.error("n_action_guide_dialog_alert: post step \(nextStep.event)")
            self.trackClick(buttonInfo)
            // 跳转账号安全中心前，关闭 Panel 弹窗
            if buttonInfo.actionType == .sessionReauthSetupPassword, topVC is UDActionPanel {
                topVC.dismiss(animated: true) {
                    postEventBus()
                }
            } else {
                postEventBus()
            }
        }

        let config = UDDialogUIConfig(style: .vertical)
        let alert = UDDialog(config: config)
        alert.setTitle(text: info.title ?? "")
        alert.setContent(text: info.subtitle ?? "")
        if let buttonList = info.buttonList {
            buttonList.enumerated().forEach { (index, button) in
                if index == 0 {
                    alert.addPrimaryButton(text: button.text ?? "", numberOfLines: 0, dismissCompletion: {
                        action(button)
                    })
                } else {
                    alert.addSecondaryButton(text: button.text ?? "", numberOfLines: 0, dismissCompletion: {
                        action(button)
                    })
                }
            }
        }
        Self.logger.error("n_action_guide_dialog_alert_show")
        topVC.present(alert, animated: true, completion: {
            self.trackViewLoad(stepInfo: info)
        })
    }

    private func logout() {
        Self.logger.error("n_action_guide_dialog", body: "logout after countdown")
        let config: LogoutConf
        if UserManager.shared.getActiveUserList().count > 1 {
            config = LogoutConf(forceLogout: true, destination: .switchUser, type: .foreground)
        } else {
            config = LogoutConf(forceLogout: true, destination: .login, type: .all)
        }

        passportService.logout(conf: config) {
            Self.logger.error("n_action_guide_dialog_alert", body: "logout interruptted")
        } onError: { message in
            Self.logger.error("n_action_guide_dialog_alert", body: "logout error: \(message)")
        } onSuccess: { _, _ in
            Self.logger.info("n_action_guide_dialog_alert", body: "logout succ")
        } onSwitch: { _ in
            Self.logger.info("n_action_guide_dialog_alert", body: "logout switch")
        }
    }

}

// Track
extension GuideDialogAlertHandler {
    private func trackViewLoad(stepInfo: GuideDialogStepInfo) {
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: "",
                                                            data: getTrackParams(collectionInfo: stepInfo.collectionInfo))
        SuiteLoginTracker.track(stepInfo.collectionInfo?.eventKey ?? "passport_session_risk_identity_verify_confirm_view",
                                params: params)
    }

    private func trackClick(_ buttonInfo: V4ShowDialogStepInfo.ActionBtn) {
        if let actionType = buttonInfo.actionType, case .sessionReauthCancel = actionType {
            return
        }
        let click = "go_to_confirm"
        let target = "none"
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: "",
                                                             click: click,
                                                             target: target,
                                                             data: getTrackParams(collectionInfo: buttonInfo.collectionInfo))
        SuiteLoginTracker.track(buttonInfo.collectionInfo?.eventKey ?? "passport_session_risk_identity_verify_confirm_click",
                                params: params)
    }

    private func getTrackParams(collectionInfo: CollectionInfo?) -> [String: Any] {
        let params = collectionInfo?.params ?? [:]
        let userID: String
        if let uid = params["user_id"] {
            userID = uid
        } else {
            userID = UserManager.shared.foregroundUser?.userID ?? ""
        }
        let scene: String = params["scene"] ?? "unknown"
        let payload = ["login_user_id": userID,
                       "scene": scene]
        return payload
    }
}

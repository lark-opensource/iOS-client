//
//  GuideDialogViewModel.swift
//  LarkAccount
//
//  Created by au on 2023/5/17.
//

import Foundation
import LarkAccountInterface
import LarkContainer
import LKCommonsLogging
import UniverseDesignFont

final class GuideDialogViewModel {

    private static let logger = Logger.log(GuideDialogViewModel.self, category: "LarkAccount")

    @Provider private var passportService: PassportService

    let stepInfo: GuideDialogStepInfo
    let context: UniContextProtocol
    let vcHandler: EventBusVCHandler?

    init(stepInfo: GuideDialogStepInfo, context: UniContextProtocol, vcHandler: EventBusVCHandler?) {
        self.stepInfo = stepInfo
        self.context = context
        self.vcHandler = vcHandler
    }

    func postButtonInfo(buttonInfo: V4ShowDialogStepInfo.ActionBtn, completion: @escaping () -> Void) {
        trackClick(buttonInfo)
        guard let nextStep = buttonInfo.nextStep else {
            if buttonInfo.actionType == .gotIt {
                Self.logger.info("n_action_guide_dialog: got it to logout")
                // 风险场景下的登出
                logout(fromCountdown: false)
                return
            }
            completion()
            Self.logger.error("n_action_guide_dialog_action_panel: no step")
            return
        }
        Self.logger.info("n_action_guide_dialog: post step \(nextStep.event)")
        LoginPassportEventBus.shared.post(
            event: nextStep.event,
            context: V3RawLoginContext(
                stepInfo: nextStep.info,
                vcHandler: self.vcHandler,
                backFirst: nil,
                context: self.context
            ),
            success: {
                completion()
            }, error: { _ in
                completion()
            }
        )
    }

    func needDismiss(buttonInfo: V4ShowDialogStepInfo.ActionBtn) -> Bool {
        switch buttonInfo.actionType {
        case .sessionReauthGuideDialog, .verify:
            return false
        default:
            return true
        }
    }

    func logout(fromCountdown: Bool) {
        Self.logger.error("n_action_guide_dialog", body: "logout after countdown")
        let config: LogoutConf
        let trigger: LogoutTrigger = fromCountdown ? .sessionRiskCountdown : .sessionExpired
        if UserManager.shared.getActiveUserList().count > 1 {
            config = LogoutConf(forceLogout: true, trigger: trigger, destination: .switchUser, type: .foreground)
        } else {
            config = LogoutConf(forceLogout: true, trigger: trigger, destination: .login, type: .all)
        }

        passportService.logout(conf: config) {
            Self.logger.error("n_action_guide_dialog", body: "logout interruptted")
        } onError: { message in
            Self.logger.error("n_action_guide_dialog", body: "logout error: \(message)")
        } onSuccess: { _, _ in
            Self.logger.info("n_action_guide_dialog", body: "logout succ")
        } onSwitch: { _ in
            Self.logger.info("n_action_guide_dialog", body: "logout switch")
        }
    }
}

// Track
extension GuideDialogViewModel {

    // track view
    func trackViewLoad() {
        SuiteLoginTracker.track(stepInfo.collectionInfo?.eventKey ?? "passport_session_risk_identity_verify_remind_view",
                                params: getTrackParams(collectionInfo: stepInfo.collectionInfo))
    }

    // track click
    func trackClick(_ buttonInfo: V4ShowDialogStepInfo.ActionBtn) {
        let click: String
        let target: String
        switch buttonInfo.actionType {
        case .sessionReauthExemptRemind:
            click = "wait"
            target = "none"
        default:
            click = "go_to_confirm"
            target = "none"
        }

        let params = SuiteLoginTracker.makeCommonClickParams(flowType: "", click: click, target: target, data: getTrackParams(collectionInfo: buttonInfo.collectionInfo))
        SuiteLoginTracker.track(buttonInfo.collectionInfo?.eventKey ?? "passport_session_risk_identity_verify_remind_click",
                                params: params)
    }

    private func getRemindType(_ value: String) -> String {
        switch value {
        case "0":
            return "first_countdown"
        case "1":
            return "second_countdown"
        case "2":
            return "account_logout"
        default:
            return ""
        }
    }

    private func getTrackParams(collectionInfo: CollectionInfo?) -> [String: Any] {
        let params = collectionInfo?.params ?? [:]
        let userID: String
        if let uid = params["user_id"] {
            userID = uid
        } else {
            userID = UserManager.shared.foregroundUser?.userID ?? "" // user:current
        }
        let type: String = params["type"] ?? "-1"
        let scene: String = params["scene"] ?? "unknown"
        let payload = ["login_user_id": userID,
                       "type": getRemindType(type),
                       "scene": scene]
        return payload
    }
}

//
//  V3JoinTenantBaseViewModel.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/5.
//

import Foundation
import RxSwift
import LarkAlertController
import Homeric
import LarkPerf
import ECOProbeMeta

class V3JoinTenantBaseViewModel: V3ViewModel {

    let joinType: V4JoinTenantInfo.JoinType

    let api: JoinTeamAPIProtocol

    private var currentSceneForVerify: MultiSceneMonitor.Scene {
        return self.joinType == .inputTeamCode ? .joinTenantCodeVerify : .joinTenantScanVerify
    }

    private var currentSceneForConfirm: MultiSceneMonitor.Scene {
        return self.joinType == .inputTeamCode ? .joinTenantCodeConfirm : .joinTenantScanConfirm
    }

    init(
        step: String,
        joinType: V4JoinTenantInfo.JoinType,
        stepInfo: ServerInfo,
        api: JoinTeamAPIProtocol,
        context: UniContextProtocol
    ) {
        self.joinType = joinType
        self.api = api
        super.init(step: step, stepInfo: stepInfo, context: context)
    }

    public func getParams() -> (teamCode: String?, qrUrL: String?, flowType: String?) {
        return (nil, nil, nil)
    }
    
    func getServerInfo() -> ServerInfo {
        return stepInfo
    }

    func joinWithQRCode() -> Observable<Void> {
        let (teamCode, qrUrl, flowType) = getParams()
        if let code = teamCode {
            V3ViewModel.logger.info("n_action_scan_qrcode_succ", body:"teamCode: \(code))")
        }
        let sceneInfo = [
            MultiSceneMonitor.Const.scene.rawValue: self.currentSceneForConfirm.rawValue,
            MultiSceneMonitor.Const.result.rawValue: "success"
        ]
        PassportMonitor.flush(EPMClientPassportMonitorInvitationJoinCode.join_by_scan_code_request_start, context: context)
        return api.joinWithQRCode(
            TeamCodeReqBody(
                type: self.joinType.rawValue,
                teamCode: teamCode,
                qrUrl: qrUrl,
                flowType: flowType,
                sceneInfo: sceneInfo,
                context: context
            ),
            serverInfo: getServerInfo())
            .post(self.additionalInfo, context: context)
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                V3ViewModel.logger.info("n_action_join_team_by_scan_succ")
                PassportMonitor.flush(EPMClientPassportMonitorInvitationJoinCode.join_by_scan_code_request_succ, context: self.context)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                V3ViewModel.logger.error("n_action_join_team_by_scan_error", error: error)
                PassportMonitor.flush(EPMClientPassportMonitorInvitationJoinCode.join_by_scan_code_request_fail, context: self.context, error: error)
            })
    }
}

extension V3JoinTenantBaseViewModel {
    enum AlertScene {
        case joinTenantCode
        case joinTenantScan
    }

    static func alertConfirm(v3LoginService: V3LoginService, title: String, content: String, confirm: @escaping () -> Void, cancel: @escaping () -> Void, vc: UIViewController, scene: AlertScene, trackPath: String?) {
        let trackParam = [TrackConst.path: trackPath ?? ""]

        let controller = LarkAlertController()
        controller.setTitle(text: title)
        controller.setFixedWidthContent(text: content)
        controller.addSecondaryButton(
            text: I18N.Lark_Login_V3_Join_Team_Dialog_Cancel,
            dismissCompletion: {
                cancel()
                switch scene {
                case .joinTenantCode:
                    SuiteLoginTracker.track(Homeric.JOIN_TENANT_CODE_ALERT_CLICK_CANCEL, params: trackParam)
                case .joinTenantScan:
                    SuiteLoginTracker.track(Homeric.JOIN_TENANT_SCAN_ALERT_CLICK_CANCEL, params: trackParam)
                }
            })
        controller.addPrimaryButton(
            text: I18N.Lark_Login_V3_Join_Team_Dialog_Sure,
            dismissCompletion: {
                confirm()
                switch scene {
                case .joinTenantCode:
                    SuiteLoginTracker.track(Homeric.JOIN_TENANT_CODE_ALERT_CLICK_CONFIRM, params: trackParam)
                case .joinTenantScan:
                    SuiteLoginTracker.track(Homeric.JOIN_TENANT_SCAN_ALERT_CLICK_CONFIRM, params: trackParam)
                }
            })
        vc.present(controller, animated: true, completion: nil)
    }
}

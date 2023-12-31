//
//  V4JoinTenantCodeViewModel.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/2.
//

import Foundation
import RxSwift
import LarkContainer
import ECOProbeMeta
import Homeric
import LKCommonsLogging

class V4JoinTenantCodeViewModel: V3JoinTenantBaseViewModel {
    @Provider var loginApi: LoginAPI
    let logger = Logger.plog(V4JoinTenantCodeViewModel.self, category: "SuiteLogin.V4JoinTenantCodeViewModel")

    let joinTenantCodeInfo: V4JoinTenantCodeInfo

    init(
        step: String,
        joinTenantCodeInfo: V4JoinTenantCodeInfo,
        api: JoinTeamAPIProtocol,
        context: UniContextProtocol
    ) {
        self.joinTenantCodeInfo = joinTenantCodeInfo
        super.init(
            step: step,
            joinType: .inputTeamCode,
            stepInfo: joinTenantCodeInfo,
            api: api,
            context: context
        )
    }

    var code: String = ""
    
    override func getServerInfo() -> ServerInfo {
        return joinTenantCodeInfo
    }

    public override func getParams() -> (teamCode: String?, qrUrL: String?, flowType: String?) {
        return (code, nil, self.joinTenantCodeInfo.flowType)
    }

    public func joinTenant(tenantCode: String) -> Observable<()> {
        logger.info("n_action_join_team_by_code_req")
        PassportMonitor.flush(EPMClientPassportMonitorInvitationJoinCode.join_by_team_code_request_start, context: context)
        return self.loginApi.joinTenantByCode(
            serverInfo: self.joinTenantCodeInfo,
            teamCode: code,
            context: self.context
        )
        .post(self.additionalInfo, context: self.context)
        .do(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.logger.info("n_action_join_team_by_code_succ")
            PassportMonitor.flush(EPMClientPassportMonitorInvitationJoinCode.join_by_team_code_request_succ, context: self.context)
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.joinTenantCodeInfo.flowType ?? "", click: "next", target: TrackConst.passportUserInfoSettingView, data: ["verify_result": "success"])
            SuiteLoginTracker.track(Homeric.PASSPORT_TEAM_CODE_INPUT_CLICK, params: params)
        }, onError: { [weak self] error in
            guard let self = self else { return }
            self.logger.error("n_action_join_team_by_code_error", error: error)
            PassportMonitor.flush(EPMClientPassportMonitorInvitationJoinCode.join_by_team_code_request_fail, context: self.context, error: error)
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.joinTenantCodeInfo.flowType ?? "", click: "next", target: TrackConst.passportUserInfoSettingView, data: ["verify_result": "failed"])
            SuiteLoginTracker.track(Homeric.PASSPORT_TEAM_CODE_INPUT_CLICK, params: params)
        })
    }

}

extension V4JoinTenantCodeViewModel {
    var title: String {
        return joinTenantCodeInfo.title
    }

    var subtitle: NSAttributedString {
        return attributedString(for: joinTenantCodeInfo.subtitle)
    }

    var subtitleSwitchScanText: NSAttributedString {
        return attributedString(for: joinTenantCodeInfo.switchButton?.text)
    }
}

//
//  PassportMonitorMetaJoin.swift
//  LarkAccount
//
//  Created by zhaoKejie on 2023/5/16.
//

import Foundation
import ECOProbeMeta

final class PassportMonitorMetaJoin: OPMonitorCodeBase {

    static let domain = "client.monitor.passport.join"

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: PassportMonitorMetaJoin.domain, code: code, level: level, message: message)
    }

}

extension PassportMonitorMetaJoin {
    static let loginJoinEnter = PassportMonitorMetaJoin(code: 10010,
                                                     level: OPMonitorLevelNormal,
                                                     message: "login_join_enter")

    static let loginJoinCancel = PassportMonitorMetaJoin(code: 10011,
                                                             level: OPMonitorLevelNormal,
                                                             message: "login_join_cancel")

    static let loginJoinConfirmStart = PassportMonitorMetaJoin(code: 10012,
                                                             level: OPMonitorLevelNormal,
                                                             message: "login_join_confirm_start")

    static let loginJoinConfirmResult = PassportMonitorMetaJoin(code: 10013,
                                                             level: OPMonitorLevelNormal,
                                                             message: "login_join_confirm_result")

    static let loginJoinRefuseCheckStart = PassportMonitorMetaJoin(code: 10014,
                                                             level: OPMonitorLevelNormal,
                                                             message: "login_join_refuse_check_start")

    static let loginJoinRefuseCheckResult = PassportMonitorMetaJoin(code: 10015,
                                                             level: OPMonitorLevelNormal,
                                                             message: "login_join_refuse_check_result")

    static let loginJoinRefuseConfirmStart = PassportMonitorMetaJoin(code: 10016,
                                                             level: OPMonitorLevelNormal,
                                                             message: "login_join_refuse_confirm_start")

    static let loginJoinRefuseConfirmResult = PassportMonitorMetaJoin(code: 10017,
                                                             level: OPMonitorLevelNormal,
                                                             message: "login_join_refuse_confirm_result")

    static let joinTenantEnter = PassportMonitorMetaJoin(code: 10020,
                                                     level: OPMonitorLevelNormal,
                                                     message: "join_tenant_enter")

    static let joinTenantCancel = PassportMonitorMetaJoin(code: 10021,
                                                             level: OPMonitorLevelNormal,
                                                             message: "join_tenant_cancel")

    static let joinTenantTeamcodeEnter = PassportMonitorMetaJoin(code: 10030,
                                                             level: OPMonitorLevelNormal,
                                                             message: "join_tenant_teamcode_enter")

    static let joinTenantTeamcodeCancel = PassportMonitorMetaJoin(code: 10031,
                                                             level: OPMonitorLevelNormal,
                                                             message: "join_tenant_teamcode_cancel")

    static let joinTenantTeamcodeStart = PassportMonitorMetaJoin(code: 10032,
                                                             level: OPMonitorLevelNormal,
                                                             message: "join_tenant_teamcode_start")

    static let joinTenantTeamcodeResult = PassportMonitorMetaJoin(code: 10033,
                                                             level: OPMonitorLevelNormal,
                                                             message: "join_tenant_teamcode_result")

    static let joinTenantQrcodeStart = PassportMonitorMetaJoin(code: 10040,
                                                             level: OPMonitorLevelNormal,
                                                             message: "join_tenant_qrcode_start")

    static let joinTenantQrcodeResult = PassportMonitorMetaJoin(code: 10041,
                                                             level: OPMonitorLevelNormal,
                                                             message: "join_tenant_qrcode_result")




}

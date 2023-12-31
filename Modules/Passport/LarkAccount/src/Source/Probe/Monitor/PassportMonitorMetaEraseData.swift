//
//  PassportMonitorMetaEraseData.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/7/17.
//

import Foundation
import ECOProbeMeta

enum MonitorEraseDataDurationFlow: String {
    case erase
}

final class PassportMonitorMetaEraseData: OPMonitorCodeBase {

    private static let domain = "client.monitor.passport.logout_eraser"

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: Self.domain, code: code, level: level, message: message)
    }
}

extension PassportMonitorMetaEraseData {
    static let eraser_start = PassportMonitorMetaEraseData(code: 10000,
                                                           level: OPMonitorLevelNormal,
                                                           message: "logout_all_eraser_start")

    static let eraser_succ = PassportMonitorMetaEraseData(code: 10001,
                                                          level: OPMonitorLevelNormal,
                                                          message: "logout_all_eraser_end_succ")

    static let eraser_fail = PassportMonitorMetaEraseData(code: 10002,
                                                          level: OPMonitorLevelError,
                                                          message: "logout_all_eraser_end_fail")

    static let eraser_retry = PassportMonitorMetaEraseData(code: 10003,
                                                           level: OPMonitorLevelNormal,
                                                           message: "logout_all_eraser_fail_retry")

    static let eraser_cancel = PassportMonitorMetaEraseData(code: 10004,
                                                            level: OPMonitorLevelNormal,
                                                            message: "logout_all_eraser_fail_cancel")

    static let eraser_confirm_reset = PassportMonitorMetaEraseData(code: 10005,
                                                                   level: OPMonitorLevelNormal,
                                                                   message: "logout_all_eraser_reset_confirm")

}


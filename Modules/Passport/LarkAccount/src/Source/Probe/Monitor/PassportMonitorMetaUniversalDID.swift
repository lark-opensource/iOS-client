//
//  PassportMonitorMetaUniversalDID.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/3/23.
//

import ECOProbeMeta
import Foundation

final class PassportMonitorMetaUniversalDID: OPMonitorCodeBase {

    private static let domain = "client.passport.monitor.universal_did"

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: PassportMonitorMetaUniversalDID.domain, code: code, level: level, message: message)
    }

}

extension PassportMonitorMetaUniversalDID {
    static let rustSetDeviceInfoFail = PassportMonitorMetaUniversalDID(code: 10018,
                                                     level: OPMonitorLevelError,
                                                     message: "rust_set_did_fail")
}


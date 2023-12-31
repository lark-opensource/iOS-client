//
//  KaIdentity.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/23.
//

import Foundation
import LKCommonsLogging
import LarkAccountInterface

enum KaIdentityStatus {
    case externalTokenValid
    case externalTokenNeedRefresh
    case refreshTokenExpired
}

struct KaIdentity: Codable {

    static let logger = Logger.log(KaIdentity.self, category: "SuiteLogin.KaIdentity")

    static let HALF_DAY_IN_SECONDS: TimeInterval = 12 * 60 * 60

    let externalTokenExpiresTimestamp: TimeInterval

    let refreshTokenExpiresTimestamp: TimeInterval

    /// raw data
    let extraIdentity: ExtraIdentity

    init(_ extraIdentity: ExtraIdentity) {
        self.extraIdentity = extraIdentity
        let currentTimestamp = Date().timeIntervalSince1970

        var externalTokenExpiresTimestamp: TimeInterval
        if let expire = TimeInterval(extraIdentity.tokenExpires) {
            externalTokenExpiresTimestamp = currentTimestamp + expire
        } else {
            externalTokenExpiresTimestamp = currentTimestamp
            KaIdentity.logger.error("invalid external token expires: \(extraIdentity.tokenExpires)")
        }
        self.externalTokenExpiresTimestamp = externalTokenExpiresTimestamp

        var refreshTokenExpiresTimestamp: TimeInterval
        if let expire = TimeInterval(extraIdentity.refreshTokenExpires) {
            refreshTokenExpiresTimestamp = currentTimestamp + expire
        } else {
            refreshTokenExpiresTimestamp = currentTimestamp
            KaIdentity.logger.error("invalid refresh token expires: \(extraIdentity.refreshTokenExpires)")
        }
        self.refreshTokenExpiresTimestamp = refreshTokenExpiresTimestamp
    }

    func status() -> KaIdentityStatus {
        let currentTimestamp = Date().timeIntervalSince1970
        if (externalTokenExpiresTimestamp - currentTimestamp) > KaIdentity.HALF_DAY_IN_SECONDS {
            return .externalTokenValid
        }
        if refreshTokenExpiresTimestamp < currentTimestamp {
            return .refreshTokenExpired
        }
        return .externalTokenNeedRefresh
    }
}

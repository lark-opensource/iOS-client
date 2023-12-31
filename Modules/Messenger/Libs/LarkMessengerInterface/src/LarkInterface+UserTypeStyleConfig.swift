//
//  LarkInterface+UserTypeStyleApplyConfig.swift
//  LarkMessengerInterface
//
//  Created by Jiayun Huang on 2019/12/14.
//

import Foundation
import LarkAccountInterface

typealias UserTypeStyleApplyHandler = (PassportUserType) -> UserStyleApplyConfig

enum UserStyleApplyConfig {
    case on
    case off
}

extension UserStyleApplyConfig {
    static func apply(unknwon: UserStyleApplyConfig,
                      c: UserStyleApplyConfig,
                      simple: UserStyleApplyConfig,
                      standard: UserStyleApplyConfig) -> UserTypeStyleApplyHandler {
        func getUserStyleConfig(userType: PassportUserType) -> UserStyleApplyConfig {
            switch userType {
            case .undefined:
                return unknwon
            case .c:
                return c
            case .simple:
                return simple
            case .standard:
                return standard
            @unknown default:
                return unknwon
            }
        }
        return getUserStyleConfig
    }

    static func apply(standard: UserStyleApplyConfig,
                      others: UserStyleApplyConfig) -> UserTypeStyleApplyHandler {
        apply(unknwon: others, c: others, simple: others, standard: standard)
    }
}

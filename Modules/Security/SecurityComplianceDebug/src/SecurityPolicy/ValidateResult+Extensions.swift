//
//  ValidateResult+Extensions.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/12/4.
//

import Foundation
import LarkSecurityComplianceInterface

extension ValidateResult: CustomStringConvertible {
    public var description: String {
        "ValidateResult(userResolver: userResolver, result: \(result), extra: \(extra)"
    }
}

extension ValidateExtraInfo: CustomStringConvertible {
    public var description: String {
        "ValidateExtraInfo(resultSource: \(resultSource), errorReason: \(errorReason, defaultValue: "nil"), resultMethod: \(resultMethod, defaultValue: "nil"), isCredible: \(isCredible), rawActions: \(rawActions, defaultValue: "nil"), logInfos: \(logInfos))"
    }
}

extension ValidateLogInfo: CustomStringConvertible{
    public var description: String {
        "ValidateLogInfo(uuid: \(uuid) , policySetKeys: \(policySetKeys, defaultValue: "nil"))"
    }
}

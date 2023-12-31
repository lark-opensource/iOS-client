//
//  SCDebugModelSectionType.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2022/10/8.
//

import UIKit

public enum SCDebugSectionType: Int, CaseIterable {
    case debugEntrance
    case `default`
    case securityPolicy
    case conditionAccess
    case sncInfra
    case deviceSecurity
    case securityAudit
    case encryptionUpgrade
    case settingsAndFG
    case appLock
}


public extension SCDebugSectionType {
    var name: String {
        switch self {
        case .debugEntrance:
            return "高级调试"
        case .default:
            return "默认"
        case .conditionAccess:
            return "访问控制"
        case .deviceSecurity:
            return "终端安全"
        case .sncInfra:
            return "安全基建"
        case .securityPolicy:
            return "安全SDK"
        case .securityAudit:
            return "权限SDK"
        case .encryptionUpgrade:
            return "密钥升级"
        case .settingsAndFG:
            return "settings & FG"
        case .appLock:
            return "锁屏保护"
        }
    }

    static var casesForDebugEntrance: [SCDebugSectionType] {
        var cases = Self.allCases
        cases.removeAll(where: { $0 == .debugEntrance })
        return cases
    }
}

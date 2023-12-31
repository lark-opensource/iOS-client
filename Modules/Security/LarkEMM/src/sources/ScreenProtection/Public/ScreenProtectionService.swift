//
//  ScreenProtectionService.swift
//  LarkEMM
//
//  Created by qingchun on 2022/9/14.
//

import Foundation

// 业务方类型，default为全局开关类型
public enum ScreenProtectionBiz: Int {
    case `default`
    case imGroup
}

public protocol ScreenProtectionService {

    var isSecureProtection: Bool { get }

    func setScreenProtection(_ biz: ScreenProtectionBiz, enabled: Bool) throws

    func vcScreenCastChange(_ vcCast: Bool)

    func register(_ observer: ScreenProtectionChangeAction)

    func unRegister(_ observer: ScreenProtectionChangeAction)
}

public protocol ScreenProtectionChangeAction: AnyObject {
    var identifier: String { get }

    func onScreenProtectionChange()
}

final class ScreenProtectionServiceImp: ScreenProtectionService {

    var isSecureProtection: Bool { false }

    func setScreenProtection(_ biz: ScreenProtectionBiz, enabled: Bool) throws {

    }

    func vcScreenCastChange(_ vcCast: Bool) {

    }

    func register(_ observer: ScreenProtectionChangeAction) {

    }

    func unRegister(_ observer: ScreenProtectionChangeAction) {

    }
}

//
//  SCSetting.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/10/9.
//

import Foundation
import LarkContainer

public struct SCSetting {
    public static let logTag = "security_compliance_sc_setting"

    public static func staticBool(scKey: SCSettingKey, userResolver: UserResolver) -> Bool {
        do {
            let service = try userResolver.resolve(assert: SCSettingService.self)
            let value = service.bool(scKey)
            SCLogger.info("\(scKey.rawValue) \(value)", tag: SCSetting.logTag)
            return value
        } catch {
            SCLogger.error("SCSettingsService resolve error \(error)")
            return false
        }
    }

    public static func realTimeFG(scKey: SCFGKey, userResolver: UserResolver) -> Bool {
        do {
            let service = try userResolver.resolve(assert: SCFGService.self)
            let value = service.realtimeValue(scKey)
            SCLogger.info("\(scKey.rawValue) \(value)", tag: SCSetting.logTag)
            return value
        } catch {
            SCLogger.error("SCFGService resolve error \(error)")
            return false
        }
    }
}

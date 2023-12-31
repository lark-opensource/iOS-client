//
//  EMMConfig.swift
//  LarkEMM
//
//  Created by ByteDance on 2022/10/24.
//

import Foundation
import LarkSecurityComplianceInfra
import LarkContainer
import LarkFoundation

enum OtherEMMIntergrateState: Int {
    case unknown
    case unintegrated
    case integrated
}

public protocol EMMConfig {
    var isPasteProtectDisabled: Bool { get }
}

public class EMMConfigImp: EMMConfig, UserResolverWrapper {
    
    static var isIntergrateOtherEMM: Bool?
    private static let intergrateOtherEMMKey = "LarkEMM_intergrateOtherEMM_" + Utils.appVersion
    
    let settings: Settings
    
    public var isPasteProtectDisabled: Bool {
        if pasteProtectionDisalbed {
            return true
        }
        Self.isIntergrateOtherEMM == nil ? Self.isIntergrateOtherEMM = Self.isUUServer() : ()
        if Self.isIntergrateOtherEMM.isTrue {
            return true
        }
        return false
    }

    var pasteProtectionDisalbed: Bool {
        guard settings.enableSecuritySettingsV2.isTrue else {
            return settings.pasteProtectionDisalbed ?? false
        }
        return SCSetting.staticBool(scKey: .pasteProtectionDisalbed, userResolver: userResolver)
    }
    
    private static func isUUServer() -> Bool {
#if !IS_KA
        return false
#endif
        let scKeyValueStorage = SCKeyValue.globalUserDefault()
        let otherEMMIntergrateState: Int = scKeyValueStorage.value(forKey: intergrateOtherEMMKey) ?? 0
        if otherEMMIntergrateState != 0 {
            SCLogger.info("Paste protect get intergrate UUServer value: \(otherEMMIntergrateState) with key: \(intergrateOtherEMMKey)")
            return otherEMMIntergrateState == OtherEMMIntergrateState.integrated.rawValue
        }
        let isIntergrateUUServer = Bundle(identifier: "com.uusafe.UUServer") != nil
        scKeyValueStorage.set(isIntergrateUUServer ? OtherEMMIntergrateState.integrated.rawValue : OtherEMMIntergrateState.unintegrated.rawValue, forKey: intergrateOtherEMMKey)
        SCLogger.info("Paste protect set intergrate UUServer value: \(isIntergrateUUServer) for key :\(intergrateOtherEMMKey)")
        return isIntergrateUUServer
    }
    
    public let userResolver: UserResolver
    
    init(resolver: UserResolver) throws {
        userResolver = resolver
        settings = try resolver.resolve(assert: Settings.self)
    }
}

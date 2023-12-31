//
//  OpenSchemaRefactorPolicy.swift
//  TTMicroApp
//
//  Created by zhaojingxin on 2022/12/20.
//

import Foundation
import LarkSetting

@objcMembers
public final class OpenSchemaRefactorPolicy: NSObject {
    
    static public var refactorEnabled: Bool {
        FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.api.openschema_refactor_enabled")
    }
}

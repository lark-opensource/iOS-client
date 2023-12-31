//
//  OpenAPIConfig.swift
//  SKInfra
//
//  Created by ByteDance on 2023/4/4.
//

import Foundation

public struct OpenAPI {
    public struct API {
        public static let getDocsConfig = "/api/obj_setting/get/"
    }
    
    public static var resouceUpdateInterval: TimeInterval {
        let remoteInterval = SettingConfig.offlineResourceUpdateInterval
        if let remoteInterval = remoteInterval, remoteInterval > 0 {
            return TimeInterval(remoteInterval)
        } else {
            return 5 * 60
        }
    }
}

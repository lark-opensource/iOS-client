//
//  OPAppConfig.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/17.
//

import Foundation

@objcMembers open class OPProjectConfig: OPFileConfig {
    
    open override func preParsePropeties(_ appendPropeties: [Any] = []) -> [Any] {
        if let appid = appid {
            return super.preParsePropeties(appendPropeties) + [appid]
        } else {
            return super.preParsePropeties(appendPropeties)
        }
    }
    
    public lazy var appid: String? = {
        return configData["appid"] as? String
    }()
}

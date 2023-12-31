//
//  NativeAppContainerConfig.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2022/12/28.
//

import Foundation
import OPSDK

@objcMembers class NativeAppContainerConfig: NSObject, OPContainerConfigProtocol {
    var previewToken: String?
    
    var enableAutoDestroy: Bool
    
    
    public override init () {
        self.previewToken = ""
        self.enableAutoDestroy = false
    }
    
}

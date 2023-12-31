//
//  OPContainerConfig.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/18.
//

import Foundation

/// 初始化数据协议的默认实现
@objcMembers open class OPContainerConfig: NSObject, OPContainerConfigProtocol {
    
    public let previewToken: String?
    
    public var enableAutoDestroy: Bool
    
    public init(previewToken: String?, enableAutoDestroy: Bool) {
        self.previewToken = previewToken
        self.enableAutoDestroy = enableAutoDestroy
    }
    
}

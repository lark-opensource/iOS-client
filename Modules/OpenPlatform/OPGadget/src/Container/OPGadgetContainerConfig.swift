//
//  OPGadgetContainerConfig.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/18.
//

import Foundation
import OPSDK

/// gadget 初始化数据协议的默认实现
@objcMembers public final class OPGadgetContainerConfig: OPContainerConfig, OPGadgetContainerConfigProtocol {
    
    public let wsForDebug: String?
    
    public let ideDisableDomainCheck: String?
    
    public required init(previewToken: String?, enableAutoDestroy: Bool, wsForDebug: String? = nil, ideDisableDomainCheck: String? = nil) {
        self.wsForDebug = wsForDebug
        self.ideDisableDomainCheck = ideDisableDomainCheck
        super.init(previewToken: previewToken, enableAutoDestroy: enableAutoDestroy)
    }
}

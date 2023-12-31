//
//  OPContainerConfig.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/16.
//

import Foundation
import ECOProbe

// MARK: - Common

/// 初始化数据协议
@objc public protocol OPContainerConfigProtocol: NSObjectProtocol {
    
    var previewToken: String? { get }
    
    /// 允许自动回收
    var enableAutoDestroy: Bool { get set }
    
}

// MARK: - Gadget

/// gadget 初始化数据协议
@objc public protocol OPGadgetContainerConfigProtocol: OPContainerConfigProtocol {
    
    /// 真机调试的地址
    var wsForDebug: String? { get }
    /// IDE web-view安全域名调试开关
    var ideDisableDomainCheck: String? { get }
}



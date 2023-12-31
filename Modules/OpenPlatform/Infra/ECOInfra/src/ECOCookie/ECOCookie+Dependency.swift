//
//  ECOCookie+Dependency.swift
//  ECOInfra
//
//  Created by Meng on 2021/2/9.
//

import Foundation
import ECOProbe

/// ECOCookieDependency
public protocol ECOCookieDependency {
    
    /// OPMonitor 这个扩展方法实现在 TTMicrpApp，而 Cookie 模块需要提供给 TTMciroApp 使用，so...
    @discardableResult
    func setGadgetId(_ gadgetId: GadgetCookieIdentifier, for monitor: OPMonitor) -> OPMonitor
}

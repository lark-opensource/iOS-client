//
//  WindowService.swift
//  LarkSecurityComplianceInterface
//
//  Created by ByteDance on 2023/9/11.
//

import Foundation
import LarkContainer

public protocol WindowService {
    
    func createLSCWindow(frame: CGRect) -> UIWindow
    
    /// 判断是否为安全定义的window类型
    /// - Parameter window: 待判断的window
    /// - Returns: 是否为安全定义
    func isLSCWindow(_ window: UIWindow) -> Bool
}

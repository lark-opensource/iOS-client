//
//  PowerOptimizeConfigProvider.swift
//  SKInfra
//
//  Created by ByteDance on 2023/11/16.
//

import Foundation

/// 功耗优化配置提供者, 在SKCommon.CommonModule注入
public protocol PowerOptimizeConfigProvider {
    
    /// SKBrowser.JSServiceUtil对于evaluateJS调用会修正特殊字符，优化：只针对evaluateJSOptList中的callback名称进行修正
    var evaluateJSOptEnable: Bool { get }
    
    /// SKBrowser.JSServiceUtil对于evaluateJS调用会修正特殊字符，优化：只针对evaluateJSOptList中的callback名称进行修正
    var evaluateJSOptList: [String] { get }
    
    /// Space列表页对于时间戳格式化频繁调用，优化：复用NSDateFormatter
    var dateFormatOptEnable: Bool { get }
    
    /// 前端包资源文件名->文件路径映射使用本地plist文件，优化：对plist进行内存缓存
    var fePkgFilePathsMapOptEnable: Bool { get }
    
    /// 使用VC的降级策略
    var vcPowerDowngradeEnable: Bool { get }
}

//
//  WorkplaceWidgetLoadType.swift
//  LarkOpenWorkplace
//
//  Created by ByteDance on 2023/6/6.
//

import Foundation

/// Widget 组件加载类型
public enum WorkplaceWidgetLoadType {
    /// 正常加载
    case normal
    /// 用户点击错误页重试
    case userRetry
    /// 业务调用 context.host.reload()
    case bizReload
    /// 宿主自动触发错误页重新加载
    case hostReload
    
    /// 宿主自动触发重新加载的细节暂不透出，后续需要再做
    /*
    enum HostReloadType {
        case networkxxxx
        case xxx
    }
    */
}

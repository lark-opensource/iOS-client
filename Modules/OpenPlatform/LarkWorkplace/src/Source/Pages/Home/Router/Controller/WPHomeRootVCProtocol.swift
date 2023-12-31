//
//  WPHomeRootVCProtocol.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/12/21.
//

import Foundation
import ECOProbe

/// childVC -> parentVC
protocol WPHomeRootVCProtocol: AnyObject {
    /// 首页埋点 Tracker
    var tracker: WPHomeTracker { get }

    /// 顶部导航栏高度，包含 statusbar
    var topNavH: CGFloat { get }

    /// 获取底部 TabBar 高度
    var botTabH: CGFloat { get }
    
    /// 获取定制工作台数量
    var templatePortalCount: Int { get }

    func reportFirstScreenDataReadyIfNeeded()

    func rootReloadNaviBar()
}

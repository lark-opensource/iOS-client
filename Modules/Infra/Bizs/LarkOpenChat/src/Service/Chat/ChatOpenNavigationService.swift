//
//  ChatOpenNavigationService.swift
//  LarkOpenChat
//
//  Created by zc09v on 2022/1/11.
//

import UIKit
import Foundation
import UniverseDesignColor

public enum OpenChatNavigationBarStyle {
    case lightContent
    case darkContent
    case custom(UIColor) /// 自定义颜色，会将图标以及标题和副标题统一染色

    public func elementTintColor() -> UIColor {
        switch self {
        case .lightContent:
            return UIColor.ud.N900
        case .darkContent:
            return UIColor.ud.N00.alwaysLight
        case .custom(let color):
            return color
        }
    }
}
public protocol ChatOpenNavigationService: AnyObject {
    /// 刷新整个导航栏
    func refresh()

    /// 刷新导航栏右侧按钮区
    func refreshRightItems()

    /// 刷新导航栏左侧按钮区
    func refreshLeftItems()

    /// 刷新导航栏title区域
    func refreshCenterContent()

    /// 获取当前navgationBar的展示样式
    func navigationBarDisplayStyle() -> OpenChatNavigationBarStyle
}

/// DefaultChatOpenNavigationService的默认实现
public final class DefaultChatOpenNavigationService: ChatOpenNavigationService {
    public init() {}
    /// 刷新整个导航栏
    public func refresh() {}
    /// 刷新导航栏右侧按钮区
    public func refreshRightItems() {}
    /// 刷新导航栏左侧按钮区
    public func refreshLeftItems() {}
    /// 刷新导航栏title区域
    public func refreshCenterContent() {}
    /// 获取当前navgationBar的样式
    public func navigationBarDisplayStyle() -> OpenChatNavigationBarStyle { return .lightContent }
}

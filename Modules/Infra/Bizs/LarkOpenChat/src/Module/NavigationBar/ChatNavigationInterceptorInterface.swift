//
//  ChatNavigationInterceptorInterface.swift
//  LarkMessageBase
//
//  Created by ByteDance on 2023/10/27.
//

import Foundation

/// 定义拦截器 & 拦截器之间的优先级顺序
/// TODO: 多选等不同场景可通过定义过滤器实现拦截
public enum ChatNavigationSubInterceptorType: Int, CaseIterable {
    /// 导航栏宽度变化
    case zoomDisplayWidth = 0
}
/// 导航栏拦截器
public protocol ChatNavigationInterceptor: AnyObject {
    init()
    func intercept(context: ChatNavigationInterceptorContext) -> [ChatNavigationExtendItemType: Bool]
}

public protocol ChatNavigationSubInterceptor: ChatNavigationInterceptor {
    static var subType: ChatNavigationSubInterceptorType { get }
}

public struct ChatNavigationInterceptorContext {
    public var pageWidth: CGFloat
    public init(pageWidth: CGFloat) {
        self.pageWidth = pageWidth
    }
}

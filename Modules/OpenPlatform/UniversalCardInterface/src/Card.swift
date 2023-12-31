//
//  Card.swift
//  UniversalCardInterface
//
//  Created by ByteDance on 2023/8/7.
//

import Foundation
import LarkContainer

public enum UniversalCardRenderThreadMode {
    case async
    case sync
}
// 卡片外部布局相关配置
public struct UniversalCardLayoutConfig: Equatable {
    public let preferWidth: CGFloat
    public let preferHeight: CGFloat?
    public let maxHeight: CGFloat?
    public init(preferWidth: CGFloat, preferHeight: CGFloat? = nil, maxHeight: CGFloat?) {
        self.preferWidth = preferWidth
        self.preferHeight = preferHeight
        self.maxHeight = maxHeight
    }
}

public let UniversalCardTag = "UniversalCard"
// 卡片实例的协议
public protocol UniversalCardProtocol {
    // 创建卡片实例, 此时没有数据, 只需要布局配置
    // renderMode: 渲染模式, 同步在 render 后就回有高度和发生实际渲染, 异步在 render 后无法立刻拿到高度而是在子线程渲染
    static func create(resolver: UserResolver, renderMode: UniversalCardRenderThreadMode) -> Self
    // 更新布局配置, 触发卡片重新布局
    func updateLayout(layoutConfig: UniversalCardLayoutConfig)
    // 获取卡片 view
    func getView() -> UIView
    // 获取卡片尺寸(非 view 的尺寸, 而是实际渲染的内容尺寸)
    func getContentSize() -> CGSize

    /// 以下分两种渲染接口, 其中
    /// A 类: 布局和渲染在都执行, 接口独立,不需要和其他接口配套执行, 需要在主线程,
    /// B: layout 接口布局(可以在子线程), renderAfterLayout 接口渲染(需要在主线程). 需要先后调用

    //渲染接口 A: 使用输入数据渲染卡片
    func render(
        layout: UniversalCardLayoutConfig,
        source: (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig),
        lifeCycle: UniversalCardLifeCycleDelegate?,
        force: Bool
    )

    //渲染接口 A: 直接渲染卡片(使用上一次数据,一般用于环境上下文如 darkmode 变更场景)
    func render()

    //渲染接口 B: 纯布局
    func layout(
        layout: UniversalCardLayoutConfig,
        source: (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig),
        lifeCycle: UniversalCardLifeCycleDelegate?,
        force: Bool
    )
}

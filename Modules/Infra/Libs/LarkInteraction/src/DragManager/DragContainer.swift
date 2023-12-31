//
//  DragContainer.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/31.
//

import UIKit
import Foundation

/// 支持拖拽容器，通过实现这个协议可以定制一些 UIView 拖拽的能力
public protocol DragContainer {
    /// 当前 container 是否支持拖拽，如果 enable 为 false，会停止手势识别
    func dragInteractionEnable(location: CGPoint) -> Bool
    /// 当前 container 是否忽略拖拽，如果 ignore 为 true，会继续寻找下一个响应的 view
    func dragInteractionIgnore(location: CGPoint) -> Bool
    /// 获取当前 container context 参数
    func dragInteractionContext(location: CGPoint) -> DragContext?
    /// 是否把手势快速传递给某一个 view 继续识别
    func dragInteractionForward(location: CGPoint) -> UIView?
}

/// 拖拽容器方法代理, 可以通过 view extension 设置
public final class DragContainerProxy: DragContainer {

    public var dragInteractionEnable: (CGPoint) -> Bool
    public var dragInteractionIgnore: (CGPoint) -> Bool
    public var dragInteractionContext: ((CGPoint) -> DragContext?)?
    public var dragInteractionForward: ((CGPoint) -> UIView?)?

    public init(
        dragInteractionEnable: @escaping (CGPoint) -> Bool = { _ in return true },
        dragInteractionIgnore: @escaping (CGPoint) -> Bool = { _ in return false },
        dragInteractionContext: ((CGPoint) -> DragContext?)? = nil,
        dragInteractionForward: ((CGPoint) -> UIView?)? = nil
    ) {
        self.dragInteractionEnable = dragInteractionEnable
        self.dragInteractionIgnore = dragInteractionIgnore
        self.dragInteractionContext = dragInteractionContext
        self.dragInteractionForward = dragInteractionForward
    }

    public func dragInteractionEnable(location: CGPoint) -> Bool {
        return dragInteractionEnable(location)
    }

    public func dragInteractionIgnore(location: CGPoint) -> Bool {
        return dragInteractionIgnore(location)
    }

    public func dragInteractionContext(location: CGPoint) -> DragContext? {
        return dragInteractionContext?(location)
    }

    public func dragInteractionForward(location: CGPoint) -> UIView? {
        return dragInteractionForward?(location)
    }
}

//
//  DragHandler.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/31.
//

import Foundation

/// Drag 响应拖拽 handler 协议
public protocol DragInteractionHandler {
    /// 返回需要响应的 viewTag
    func dragInteractionHandleViewTag() -> String
    /// 根据当前 context 判断是否需要响应
    func dragInteractionCanHandle(context: DragContext) -> Bool
    /// 根据 viewInfo 与 context，返回响应的 DragItem
    func dragInteractionHandle(info: DragInteractionViewInfo, context: DragContext) -> [DragItem]?
}

/// TODO: 支持同时支持多个 viewTag
/// 外部注入响应 Drag handler
public struct DragHandlerImpl: DragInteractionHandler {

    /// 是否可以响应 drag
    public var canHandle: (DragContext) -> Bool
    /// 返回响应 drag 的 view tag
    public var handleViewTag: String
    /// 返回响应 drag 的 DragItem
    public var handleDragItems: (DragInteractionViewInfo, DragContext) -> [DragItem]?

    public init(
        handleViewTag: String,
        canHandle: @escaping (DragContext) -> Bool,
        handleDragItems: @escaping (DragInteractionViewInfo, DragContext) -> [DragItem]?
    ) {
        self.handleViewTag = handleViewTag
        self.canHandle = canHandle
        self.handleDragItems = handleDragItems
    }

    public func dragInteractionHandleViewTag() -> String {
        return self.handleViewTag
    }

    public func dragInteractionCanHandle(context: DragContext) -> Bool {
        return canHandle(context)
    }

    public func dragInteractionHandle(info: DragInteractionViewInfo, context: DragContext) -> [DragItem]? {
        return handleDragItems(info, context)
    }
}

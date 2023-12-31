//
//  DragItem.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/31.
//

import UIKit
import Foundation

/// 当前 DragItem 的环境参数
public final class DragItemInfo {
    weak var view: UIView?
    var viewTag: String
    var context: DragContext
    var param: DragItemParams

    init(
        viewTag: String,
        view: UIView?,
        context: DragContext,
        param: DragItemParams
    ) {
        self.viewTag = viewTag
        self.view = view
        self.context = context
        self.param = param
    }
}

/// 封装起来的 Drag Item
/// 支持定制 Drag Item 的显示效果
public struct DragItem {
    public var dragItem: UIDragItem
    public var params: DragItemParams

    public init(
        dragItem: UIDragItem,
        params: DragItemParams = DragItemParams()
    ) {
        self.dragItem = dragItem
        self.params = params
    }
}

public struct DragItemParams {
    /// drag preview 定制参数
    public var dragPreviewParameters: UIDragPreviewParameters?
    /// target drag preview 定制参数
    public var targetDragPreviewParameters: UIDragPreviewParameters?

    public init(
        dragPreviewParameters: UIDragPreviewParameters? = nil,
        targetDragPreviewParameters: UIDragPreviewParameters? = nil
    ) {
        self.dragPreviewParameters = dragPreviewParameters
        self.targetDragPreviewParameters = targetDragPreviewParameters
    }
}

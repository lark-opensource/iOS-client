//
//  TextView+Drag.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/25.
//

import UIKit
import Foundation
import LKCommonsLogging

public typealias TextDraggableView = UIView & UITextDraggable

public enum TextViewDragLifeCycle {
    case sessionWillBegin(TextDraggableView, UIDragSession)
    case sessionDidEnd(TextDraggableView, UIDragSession, UIDropOperation)
}

public final class TextViewDragDelegate: NSObject {
    public typealias LiftAnimation = (TextDraggableView, UIDragSession) -> Void
    public typealias LiftCompletion = (TextDraggableView, UIDragSession, UIViewAnimatingPosition) -> Void

    static var logger = Logger.log(TextViewDragDelegate.self, category: "Lark.Interaction")

    /// 定制支持拖拽的 item
    public var itemsBlock: (TextDraggableView, UITextDragRequest) -> [UIDragItem] = { (_, _) in
        return []
    }

    /// 可以定制 lifting 预览图
    public var liftingPreview: (
        TextDraggableView, UIDragItem, UIDragSession
    ) -> UITargetedDragPreview? = { _, _, _ in return nil }

    var liftAnimations: [LiftAnimation] = []
    var liftCompletions: [LiftCompletion] = []

    private var observers: [(TextViewDragLifeCycle) -> Void] = []

    /// 添加生命周期观察这
    public func add(observer: @escaping (TextViewDragLifeCycle) -> Void) {
        self.observers.append(observer)
    }

    public func addLift(animation: @escaping LiftAnimation) {
        liftAnimations.append(animation)
    }

    public func addLift(completion: @escaping LiftCompletion) {
        liftCompletions.append(completion)
    }

}

extension TextViewDragDelegate {
    /// 便捷的创建 TextViewDragDelegate 的方法
    /// - Parameter itemsBlock: 支持的 DragItem value
    public static func create(
        itemsBlock: @escaping (TextDraggableView, UITextDragRequest) -> [DragItemValue]
    ) -> TextViewDragDelegate {
        let drag = TextViewDragDelegate()
        drag.itemsBlock = { (textView, request) -> [UIDragItem] in
            let itemValues = itemsBlock(textView, request)
            return DragInteraction.transform(values: itemValues)
        }
        return drag
    }
}

extension TextViewDragDelegate: UITextDragDelegate {
    public func textDraggableView(
        _ textDraggableView: UIView & UITextDraggable,
        itemsForDrag dragRequest: UITextDragRequest
    ) -> [UIDragItem] {
        return itemsBlock(textDraggableView, dragRequest)
    }

    public func textDraggableView(
        _ textDraggableView: UIView & UITextDraggable,
        dragPreviewForLiftingItem item: UIDragItem,
        session: UIDragSession
    ) -> UITargetedDragPreview? {
        return liftingPreview(textDraggableView, item, session) ?? UITargetedDragPreview(view: textDraggableView)

    }

    public func textDraggableView(
        _ textDraggableView: UIView & UITextDraggable,
        willAnimateLiftWith animator: UIDragAnimating,
        session: UIDragSession
    ) {
        animator.addAnimations { [weak self] in
            self?.liftAnimations.forEach({ (animation) in
                animation(textDraggableView, session)
            })
        }
        animator.addCompletion { [weak self] (position) in
            self?.liftCompletions.forEach({ (completion) in
                completion(textDraggableView, session, position)
            })
        }
    }

    public func textDraggableView(
        _ textDraggableView: UIView & UITextDraggable,
        dragSessionWillBegin session: UIDragSession
    ) {
        let state: TextViewDragLifeCycle = .sessionWillBegin(textDraggableView, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func textDraggableView(
        _ textDraggableView: UIView & UITextDraggable,
        dragSessionDidEnd session: UIDragSession,
        with operation: UIDropOperation
    ) {
        let state: TextViewDragLifeCycle = .sessionDidEnd(textDraggableView, session, operation)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }
}

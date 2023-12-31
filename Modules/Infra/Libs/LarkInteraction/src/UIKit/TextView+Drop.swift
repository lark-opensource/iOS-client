//
//  TextView+Drop.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/25.
//

import UIKit
import Foundation
import LKCommonsLogging

public typealias TextDroppableView = UIView & UITextDroppable

public enum TextViewDropLifeCycle {
    case sessionWillBegin(TextDroppableView, UIDropSession)
    case sessionDidEnter(TextDroppableView, UIDropSession)
    case sessionDidUpdate(TextDroppableView, UIDropSession)
    case sessionDidExit(TextDroppableView, UIDropSession)
    case sessionDidEnd(TextDroppableView, UIDropSession)
}

public final class TextViewDropDelegate: NSObject {
    static var logger = Logger.log(TextViewDropDelegate.self, category: "Lark.Interaction")

    public var editableForDrop: (TextDroppableView, UITextDropRequest) -> UITextDropEditability = { _, _ in
        return .no
    }

    /// 处理数据
    public var handleBlock: (TextDroppableView, UITextDropRequest) -> Void = { _, _ in }

    /// 自定义动画
    public var dropPreview: (
        TextDroppableView, UITargetedDragPreview
    ) -> UITargetedDragPreview? = { _, _ in return nil }

    /// 定义是否响应
    public var dropProposalBlock: (TextDroppableView, UITextDropRequest) -> UITextDropProposal = { ( _, request) in
        return request.suggestedProposal
    }

    private var observers: [(TextViewDropLifeCycle) -> Void] = []

    /// 添加生命周期观察这
    public func add(observer: @escaping (TextViewDropLifeCycle) -> Void) {
        self.observers.append(observer)
    }
}

extension TextViewDropDelegate: UITextDropDelegate {
    public func textDroppableView(
        _ textDroppableView: UIView & UITextDroppable,
        willBecomeEditableForDrop drop: UITextDropRequest
    ) -> UITextDropEditability {
        return editableForDrop(textDroppableView, drop)
    }

    public func textDroppableView(
        _ textDroppableView: UIView & UITextDroppable,
        proposalForDrop drop: UITextDropRequest
    ) -> UITextDropProposal {
        return dropProposalBlock(textDroppableView, drop)
    }

    public func textDroppableView(
        _ textDroppableView: UIView & UITextDroppable,
        willPerformDrop drop: UITextDropRequest
    ) {
        handleBlock(textDroppableView, drop)
    }

    public func textDroppableView(
        _ textDroppableView: UIView & UITextDroppable,
        previewForDroppingAllItemsWithDefault defaultPreview: UITargetedDragPreview
    ) -> UITargetedDragPreview? {
        return dropPreview(textDroppableView, defaultPreview)
    }

    public func textDroppableView(
        _ textDroppableView: UIView & UITextDroppable,
        dropSessionDidEnter session: UIDropSession
    ) {
        let state: TextViewDropLifeCycle = .sessionDidEnter(textDroppableView, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func textDroppableView(
        _ textDroppableView: UIView & UITextDroppable,
        dropSessionDidUpdate session: UIDropSession
    ) {
        let state: TextViewDropLifeCycle = .sessionDidUpdate(textDroppableView, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func textDroppableView(
        _ textDroppableView: UIView & UITextDroppable,
        dropSessionDidExit session: UIDropSession
    ) {
        let state: TextViewDropLifeCycle = .sessionDidExit(textDroppableView, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func textDroppableView(
        _ textDroppableView: UIView & UITextDroppable,
        dropSessionDidEnd session: UIDropSession
    ) {
        let state: TextViewDropLifeCycle = .sessionDidEnd(textDroppableView, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }
}

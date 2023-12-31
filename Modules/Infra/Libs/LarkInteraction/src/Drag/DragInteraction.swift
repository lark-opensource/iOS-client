//
//  DragInteraction.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import Foundation
import UIKit
import LKCommonsLogging

public final class DragInteraction: NSObject, Interaction {

    static var logger = Logger.log(DragInteraction.self, category: "Lark.Interaction")

    /// Item 相关设置
    public private(set) var itemDataSource: DragItemDataSource = DragItemDataSource()
    /// preview 相关设置
    public private(set) var dragPreview: DragPreview = DragPreview()
    /// 动画 相关设置
    public private(set) var dragAnimating: DragAnimating = DragAnimating()
    /// 是否局限于当前 app，默认为  false
    public var restricted: Bool = false
    /// 是否支持在同一 App 中 move 操作， 默认为 false
    public var allowsMoveOperation = false

    public var uiInteraction: UIInteraction {
        return self.dragInteraction
    }
    public private(set) lazy var dragInteraction: UIDragInteraction = {
        let interaction = UIDragInteraction(delegate: self)
        return interaction
    }()

    private var observers: [(DragLifeCycle) -> Void] = []

    public override init() {
        super.init()
    }

    public func add(observer: @escaping (DragLifeCycle) -> Void) {
        self.observers.append(observer)
    }

    public var allowsSimultaneousDropSessions: Bool {
        set { dragInteraction.allowsSimultaneousRecognitionDuringLift = newValue }
        get { return dragInteraction.allowsSimultaneousRecognitionDuringLift }
    }

    public var isEnabled: Bool {
        set { dragInteraction.isEnabled = newValue }
        get { return dragInteraction.isEnabled }
    }
}

extension DragInteraction: UIDragInteractionDelegate {
    // MARK: - Items

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        itemsForBeginning session: UIDragSession
    ) -> [UIDragItem] {
        DragInteraction.logger.debug("itemsForBeginning")
        return itemDataSource.itemsForSession(interaction, session)
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        itemsForAddingTo session: UIDragSession,
        withTouchAt point: CGPoint
    ) -> [UIDragItem] {
        DragInteraction.logger.debug("itemsForAddingTo")
        return itemDataSource.itemsForAddingTo(interaction, session, point)
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        sessionForAddingItems sessions: [UIDragSession],
        withTouchAt point: CGPoint
    ) -> UIDragSession? {
        DragInteraction.logger.debug("sessionForAddingItems")
        return itemDataSource.sessionForAddingItems(interaction, sessions, point)
    }

    // MARK: - Animation
    public func dragInteraction(
        _ interaction: UIDragInteraction,
        willAnimateLiftWith animator: UIDragAnimating,
        session: UIDragSession
    ) {
        DragInteraction.logger.debug("willAnimateLiftWith")
        animator.addAnimations { [weak self] in
            self?.dragAnimating.liftAnimations.forEach({ (animation) in
                animation(interaction, session)
            })
        }
        animator.addCompletion { [weak self] (position) in
            self?.dragAnimating.liftCompletions.forEach({ (completion) in
                completion(interaction, session, position)
            })
        }
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        item: UIDragItem,
        willAnimateCancelWith animator: UIDragAnimating
    ) {
        DragInteraction.logger.debug("willAnimateCancelWith")
        animator.addAnimations { [weak self] in
            self?.dragAnimating.cancelAnimations.forEach({ (animation) in
                animation(interaction, item)
            })
        }
        animator.addCompletion { [weak self] (position) in
            self?.dragAnimating.cancelCompletions.forEach({ (completion) in
                completion(interaction, item, position)
            })
        }
    }

    // MARK: - Session

    public func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        DragInteraction.logger.debug("sessionWillBegin")
        let state: DragLifeCycle = .sessionWillBegin(interaction, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        session: UIDragSession,
        willAdd items: [UIDragItem],
        for addingInteraction: UIDragInteraction
    ) {
        DragInteraction.logger.debug("session willAdd")
        let state: DragLifeCycle = .sessionWillAdd(interaction, session, items, addingInteraction)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func dragInteraction(_ interaction: UIDragInteraction, sessionDidMove session: UIDragSession) {
        let state: DragLifeCycle = .sessionDidMove(interaction, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        session: UIDragSession,
        willEndWith operation: UIDropOperation
    ) {
        DragInteraction.logger.debug("willEndWith")
        let state: DragLifeCycle = .sessionWillEnd(interaction, session, operation)
        self.observers.forEach { (observer) in
            observer(state)
        }
        self.dragAnimating.endAnimations.forEach({ (animation) in
            animation(interaction, session, operation)
        })
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        session: UIDragSession,
        didEndWith operation: UIDropOperation
    ) {
        DragInteraction.logger.debug("didEndWith")
        let state: DragLifeCycle = .sessionDidEnd(interaction, session, operation)
        self.observers.forEach { (observer) in
            observer(state)
        }
        self.dragAnimating.endCompletions.forEach({ (completion) in
            completion(interaction, session, operation)
        })
    }

    public func dragInteraction(_ interaction: UIDragInteraction, sessionDidTransferItems session: UIDragSession) {
        DragInteraction.logger.debug("sessionDidTransferItems")
        let state: DragLifeCycle = .sessionDidTransferItems(interaction, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    // MARK: - Preview

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        previewForLifting item: UIDragItem,
        session: UIDragSession
    ) -> UITargetedDragPreview? {
        DragInteraction.logger.debug("previewForLifting")
        return dragPreview.liftingPreview(item, session) ?? UITargetedDragPreview(view: interaction.view!)
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        previewForCancelling item: UIDragItem,
        withDefault defaultPreview: UITargetedDragPreview
    ) -> UITargetedDragPreview? {
        DragInteraction.logger.debug("previewForCancelling")
        return dragPreview.cancelPreview(item, defaultPreview)
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        prefersFullSizePreviewsFor session: UIDragSession
    ) -> Bool {
        DragInteraction.logger.debug("prefersFullSizePreviewsFor")
        return dragPreview.prefersFullSizePreview
    }

    // MARK: - Preview

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        sessionIsRestrictedToDraggingApplication session: UIDragSession
    ) -> Bool {
        DragInteraction.logger.debug("sessionIsRestrictedToDraggingApplication")
        return restricted
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        sessionAllowsMoveOperation session: UIDragSession
    ) -> Bool {
        DragInteraction.logger.debug("sessionAllowsMoveOperation")
        return allowsMoveOperation
    }
}

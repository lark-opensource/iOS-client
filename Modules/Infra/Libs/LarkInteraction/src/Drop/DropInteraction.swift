//
//  DropInteraction.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import Foundation
import UIKit
import LKCommonsLogging

public final class DropInteraction: NSObject, Interaction {

    static var logger = Logger.log(DropInteraction.self, category: "Lark.Interaction")

    /// drop 动画相关
    public private(set) var dropAnimating: DropAnimating = DropAnimating()

    /// drop 事件 handler
    public private(set) var dropItemHandler: DropItemHandler = DropItemHandler()

    /// drop 动画相关
    public private(set) var dropPreview: DropPreview = DropPreview()

    private var observers: [(DropLifeCycle) -> Void] = []

    public override init() {
        super.init()
    }

    public var uiInteraction: UIInteraction {
        return self.dropInteraction
    }
    public private(set) lazy var dropInteraction: UIDropInteraction = {
        let interaction = UIDropInteraction(delegate: self)
        return interaction
    }()

    public func add(observer: @escaping (DropLifeCycle) -> Void) {
        self.observers.append(observer)
    }

    public var allowsSimultaneousDropSessions: Bool {
        set { dropInteraction.allowsSimultaneousDropSessions = newValue }
        get { return dropInteraction.allowsSimultaneousDropSessions }
    }
}

extension DropInteraction: UIDropInteractionDelegate {

    // MARK: - Handler
    public func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        DropInteraction.logger.debug("performDrop")
        dropItemHandler.handleDragSession(interaction, session)
    }

    public func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        DropInteraction.logger.debug("canHandle")
        return dropItemHandler.canHandle(interaction, session)
    }

    // MARK: - Animating
    public func dropInteraction(
        _ interaction: UIDropInteraction,
        item: UIDragItem,
        willAnimateDropWith animator: UIDragAnimating
    ) {
        DropInteraction.logger.debug("willAnimateDropWith")
        animator.addAnimations { [weak self] in
            self?.dropAnimating.dropAnimations.forEach({ (animation) in
                animation(interaction, item)
            })
        }
        animator.addCompletion { [weak self] (position) in
            self?.dropAnimating.dropCompletions.forEach({ (completion) in
                completion(interaction, item, position)
            })
        }
    }

    // MARK: - Life Cycle
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        DropInteraction.logger.debug("sessionDidEnter")
        let state: DropLifeCycle = .sessionDidEnter(interaction, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func dropInteraction(
        _ interaction: UIDropInteraction,
        sessionDidUpdate session: UIDropSession
    ) -> UIDropProposal {
        DropInteraction.logger.debug("sessionDidUpdate")
        let state: DropLifeCycle = .sessionDidUpdate(interaction, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
        return dropItemHandler.handleSessionDidUpdate(interaction, session)
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        DropInteraction.logger.debug("sessionDidExit")
        let state: DropLifeCycle = .sessionDidExit(interaction, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        DropInteraction.logger.debug("sessionDidEnd")
        let state: DropLifeCycle = .sessionDidEnd(interaction, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func dropInteraction(_ interaction: UIDropInteraction, concludeDrop session: UIDropSession) {
        DropInteraction.logger.debug("concludeDrop")
        let state: DropLifeCycle = .concludeDrop(interaction, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    // MARK: - Preview
    public func dropInteraction(
        _ interaction: UIDropInteraction,
        previewForDropping item: UIDragItem,
        withDefault defaultPreview: UITargetedDragPreview
    ) -> UITargetedDragPreview? {
        return dropPreview.dropPreview(interaction, item, defaultPreview)
    }
}

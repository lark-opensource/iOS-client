//
//  SwipeTransitionLayout.swift
//
//  Created by Jeremy Koch
//  Copyright © 2017 Jeremy Koch. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Layout Protocol

public protocol SwipeTransitionLayout {
    func container(view: UIView, didChangeVisibleWidthWithContext context: ActionsViewLayoutContext)
    func layout(view: UIView, atIndex index: Int, with context: ActionsViewLayoutContext)
    func visibleWidthsForViews(with context: ActionsViewLayoutContext) -> [CGFloat]
}

// MARK: - Layout Context

public struct ActionsViewLayoutContext {
    public let numberOfActions: Int
    public let orientation: SwipeActionsOrientation
    public let contentSize: CGSize
    public let visibleWidth: CGFloat
    public let minimumButtonWidth: CGFloat
    public let contentWidths: [CGFloat]
    init(numberOfActions: Int,
         orientation: SwipeActionsOrientation,
         contentSize: CGSize = .zero,
         visibleWidth: CGFloat = 0,
         minimumButtonWidth: CGFloat = 0,
         contentWidths: [CGFloat] = []) {
        self.numberOfActions = numberOfActions
        self.orientation = orientation
        self.contentSize = contentSize
        self.visibleWidth = visibleWidth
        self.minimumButtonWidth = minimumButtonWidth
        self.contentWidths = contentWidths
    }

    static func newContext(for actionsView: SwipeActionsView) -> ActionsViewLayoutContext {
        return ActionsViewLayoutContext(numberOfActions: actionsView.actions.count,
                                        orientation: actionsView.orientation,
                                        contentSize: actionsView.contentSize,
                                        visibleWidth: actionsView.visibleWidth,
                                        minimumButtonWidth: actionsView.minimumButtonWidth,
                                        contentWidths: actionsView.contentWidths)
    }
}

// MARK: - Supported Layout Implementations

final class BorderTransitionLayout: SwipeTransitionLayout {
    func container(view: UIView, didChangeVisibleWidthWithContext context: ActionsViewLayoutContext) {
    }

    func layout(view: UIView, atIndex index: Int, with context: ActionsViewLayoutContext) {
        let diff = context.visibleWidth - context.contentSize.width
        view.frame.origin.x = (CGFloat(index) * context.contentSize.width / CGFloat(context.numberOfActions) + diff) * context.orientation.scale
    }

    func visibleWidthsForViews(with context: ActionsViewLayoutContext) -> [CGFloat] {
        let diff = context.visibleWidth - context.contentSize.width
        let visibleWidth = context.contentSize.width / CGFloat(context.numberOfActions) + diff

        // visible widths are all the same regardless of the action view position
        return (0..<context.numberOfActions).map({ _ in visibleWidth })
    }
}

class DragTransitionLayout: SwipeTransitionLayout {
    func container(view: UIView, didChangeVisibleWidthWithContext context: ActionsViewLayoutContext) {
        view.bounds.origin.x = (context.contentSize.width - context.visibleWidth) * context.orientation.scale
    }

    func layout(view: UIView, atIndex index: Int, with context: ActionsViewLayoutContext) {
        view.frame.origin.x = (CGFloat(index) * context.minimumButtonWidth) * context.orientation.scale
    }

    func visibleWidthsForViews(with context: ActionsViewLayoutContext) -> [CGFloat] {
        return (0..<context.numberOfActions)
            .map({ max(0, min(context.minimumButtonWidth, context.visibleWidth - (CGFloat($0) * context.minimumButtonWidth))) })
    }
}

final class RevealTransitionLayout: DragTransitionLayout {
    override func container(view: UIView, didChangeVisibleWidthWithContext context: ActionsViewLayoutContext) {
        let width = context.minimumButtonWidth * CGFloat(context.numberOfActions)
        view.bounds.origin.x = (width - context.visibleWidth) * context.orientation.scale
    }

    override func visibleWidthsForViews(with context: ActionsViewLayoutContext) -> [CGFloat] {
        return super.visibleWidthsForViews(with: context).reversed()
    }
}

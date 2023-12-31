//
//  ContextMenuInteraction.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/12/18.
//

import Foundation
import UIKit
import LKCommonsLogging

/// 对系统 UIContextMenuInteraction 的封装
@available(iOS 13.0, *)
public final class ContextMenuInteraction: NSObject, Interaction {

    static var logger = Logger.log(ContextMenuInteraction.self, category: "Lark.Interaction")

    public var uiInteraction: UIInteraction {
        return contextInteraction
    }

    public var identifier: NSCopying?

    public var animations: ContextMenuAnimating = ContextMenuAnimating()
    public var preview: ContextMenuPreview = ContextMenuPreview()

    public var configProvider: ((UIContextMenuInteraction, CGPoint) -> UIContextMenuConfiguration?)?

    public private(set) lazy var contextInteraction: UIContextMenuInteraction = {
        let interaction = UIContextMenuInteraction(delegate: self)
        return interaction
    }()

    public func updateVisibleMenu(_ block: (UIMenu) -> UIMenu) {
        if #available(iOS 14.0, *) {
            contextInteraction.updateVisibleMenu(block)
        }
    }

    public func dismissMenu() {
        contextInteraction.dismissMenu()
    }
}

@available(iOS 13.0, *)
extension ContextMenuInteraction: UIContextMenuInteractionDelegate {

    public func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        return configProvider?(interaction, location)
    }

    public func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        ContextMenuInteraction.logger.debug("previewForHighlightingMenuWithConfiguration")
        return preview.highlightingPreview(interaction, configuration)
    }

    public func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        ContextMenuInteraction.logger.debug("previewForDismissingMenuWithConfiguration")
        return preview.dismissingPreview(interaction, configuration)
    }

    public func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionCommitAnimating
    ) {
        ContextMenuInteraction.logger.debug("interactionWillPerformPreviewActionForMenuWith")
        animator.addAnimations { [weak self] in
            self?.animations.displayAnimations.forEach({ (animation) in
                animation(interaction, configuration, animator.previewViewController)
            })
        }
        animator.addCompletion { [weak self] in
            self?.animations.displayCompletions.forEach({ (animation) in
                animation(interaction, configuration, animator.previewViewController)
            })
        }
    }

    public func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willDisplayMenuFor configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionAnimating?) {
        ContextMenuInteraction.logger.debug("interactionWillDisplay")
        animator?.addAnimations { [weak self] in
            self?.animations.displayAnimations.forEach({ (animation) in
                animation(interaction, configuration, animator?.previewViewController)
            })
        }
        animator?.addCompletion { [weak self] in
            self?.animations.displayCompletions.forEach({ (animation) in
                animation(interaction, configuration, animator?.previewViewController)
            })
        }
    }

    public func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willEndFor configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionAnimating?
    ) {
        ContextMenuInteraction.logger.debug("interactionWillEnd")
        animator?.addAnimations { [weak self] in
            self?.animations.endAnimations.forEach({ (animation) in
                animation(interaction, configuration, animator?.previewViewController)
            })
        }
        animator?.addCompletion { [weak self] in
            self?.animations.endCompletions.forEach({ (animation) in
                animation(interaction, configuration, animator?.previewViewController)
            })
        }
    }
}

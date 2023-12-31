//
//  ContextMenuPreview.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/12/18.
//

import UIKit
import Foundation

/// ContextMenuPreview 支持定制 contextMenu highlighting/dismissing preview
@available(iOS 13.0, *)
public final class ContextMenuPreview {
    public var highlightingPreview: (
        UIContextMenuInteraction, UIContextMenuConfiguration
    ) -> UITargetedPreview? = { interaction, _ in
        guard let view = interaction.view,
              view.window != nil else {
            return nil
        }
        return UITargetedPreview(view: view)
    }

    public var dismissingPreview: (
        UIContextMenuInteraction, UIContextMenuConfiguration
    ) -> UITargetedPreview? = { interaction, _ in
        guard let view = interaction.view,
              view.window != nil else {
            return nil
        }
        return UITargetedPreview(view: view)
    }

    public init() {
    }
}

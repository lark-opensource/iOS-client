//
//  LKRichView+Interaction.swift
//  LKRichView
//
//  Created by qihongye on 2021/9/7.
//

import UIKit
import Foundation

extension LKRichView: UIPointerInteractionDelegate {
    func setupPointerInteraction() {
        if #available(iOS 13.4, *) {
            self.addInteraction(UIPointerInteraction(delegate: self))
        }
    }

    @available(iOS 13.4, *)
    public func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        return defaultRegion
    }

    @available(iOS 13.4, *)
    public func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        return nil
    }
}

extension LKRichView: UIDragInteractionDelegate {
    func setupDragInteraction() {
        self.addInteraction(UIDragInteraction(delegate: self))
    }

    public func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        return []
    }

    public func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
        return nil
    }
}

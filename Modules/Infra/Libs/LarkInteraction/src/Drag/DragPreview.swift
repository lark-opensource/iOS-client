//
//  DragPreview.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import UIKit
import Foundation

public final class DragPreview {
    /// 是否需要展示全尺寸的 preview， 默认为 false
    public var prefersFullSizePreview: Bool = false

    public var liftingPreview: (UIDragItem, UIDragSession) -> UITargetedDragPreview? = { _, _ in return nil }

    public var cancelPreview: (UIDragItem, UITargetedDragPreview) -> UITargetedDragPreview? = { _, _ in return nil }

    public init() {
    }
}

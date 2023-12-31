//
//  DropPreview.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import UIKit
import Foundation

public final class DropPreview {
    public var dropPreview: (
        UIDropInteraction, UIDragItem, UITargetedDragPreview
    ) -> UITargetedDragPreview? = { _, _, _ in return nil }

    public init() {
    }
}

//
//  AlignPopoverAnchor.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/11/16.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewUI
import UniverseDesignShadow

struct AlignPopoverAnchor {

    enum AlignmentType {
        case left
        case right
        case top
        case bottom
        case center
        case auto
    }

    enum ArrowDirection {
        case left
        case right
        case up
        case down
    }

    enum PopoverWidth {
        case equalToSourceView
        case fixed(CGFloat)
    }

    var sourceView: UIView

    var highlightSourceView: Bool = false
    var alignmentType: AlignmentType = .center
    var arrowDirection: ArrowDirection = .up
    var contentWidth: PopoverWidth
    var contentHeight: CGFloat
    var contentInsets: UIEdgeInsets = .zero
    var positionOffset: CGPoint = .zero
    var minPadding: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12) // 四周与屏幕最小间距

    var cornerRadius: CGFloat = 4.0
    var borderColor: UIColor?
    var dimmingColor: UIColor = UIColor.ud.bgMask
    var shadowColor: UIColor? = UIColor.ud.N900.withAlphaComponent(0.08)
    var containerColor: UIColor
    var shadowType: UniverseDesignShadow.UDShadowType? = .s4Down

    var safeMinPadding: UIEdgeInsets {
        UIEdgeInsets(top: max(VCScene.safeAreaInsets.top, minPadding.top),
                     left: max(VCScene.safeAreaInsets.left, minPadding.left),
                     bottom: max(VCScene.safeAreaInsets.bottom, minPadding.bottom),
                     right: max(VCScene.safeAreaInsets.right, minPadding.right))
    }
}

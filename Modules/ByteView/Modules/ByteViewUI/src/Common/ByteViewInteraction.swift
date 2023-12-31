//
//  ByteInteraction.swift
//  ByteView
//
//  Created by admin on 2020/12/30.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon
import LarkInteraction

public enum ByteViewPointerShape {
    case `default`
    case roundedRect(CGSize, CGFloat?)

    @available(iOS 13.4, *)
    func toPointerShape() -> PointerShape {
        switch self {
        case .default: return .default
        case .roundedRect(let size, let radius): return .roundedSize { (_, _)  in (size, radius ?? UIPointerShape.defaultCornerRadius) }
        }
    }
}

public enum ByteViewPointerEffect {
    case highlight
    case lift
    case hover
    case overlayHover(prefersShadow: Bool = false, prefersScaledContent: Bool = true)
    case underlayHover(prefersShadow: Bool = false, prefersScaledContent: Bool = true)

    @available(iOS 13.4, *)
    func toInteraction(_ shape: ByteViewPointerShape) -> Interaction {
        let effect: PointerEffect
        switch self {
        case .highlight: effect = .highlight
        case .lift: effect = .lift
        case .hover: effect = .hover()
        case let .overlayHover(prefersShadow, prefersScaledContent):
            effect = .hover(preferredTintMode: .overlay, prefersShadow: prefersShadow, prefersScaledContent: prefersScaledContent)
        case let .underlayHover(prefersShadow, prefersScaledContent):
            effect = .hover(preferredTintMode: .underlay, prefersShadow: prefersShadow, prefersScaledContent: prefersScaledContent)
        }
        return PointerInteraction(style: PointerStyle(effect: effect, shape: shape.toPointerShape()))
    }
}

extension UIView {
    public func addInteraction(type: ByteViewPointerEffect, shape: ByteViewPointerShape = .default) {
        guard Display.pad else { return }

        if #available(iOS 13.4, *) {
            addLKInteraction(type.toInteraction(shape))
        }
    }
}

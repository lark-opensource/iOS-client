//
//  WorkPlaceVCCommon.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/12/7.
//

import LarkUIKit
import EENavigator
import LarkInteraction

extension UIViewController {
    /// isWPWindowRegularSize
    func isWPWindowRegularSize() -> Bool {
        return view.isWPWindowRegularSize()
    }
    /// isWPWindowCompactSize
    func isWPWindowCompactSize() -> Bool {
        return view.isWPWindowCompactSize()
    }
}

extension UIView {
    /// isWPWindowRegularSize
    func isWPWindowRegularSize() -> Bool {
        return isWPWindowUISizeClass(.regular)
    }
    /// isWPWindowCompactSize
    func isWPWindowCompactSize() -> Bool {
        return isWPWindowUISizeClass(.compact)
    }
    /// isWPWindowUISizeClass
    func isWPWindowUISizeClass(_ sizeClass: UIUserInterfaceSizeClass) -> Bool {
        let lkTraitCollection = window?.lkTraitCollection
        return lkTraitCollection?.horizontalSizeClass == sizeClass
    }
}

enum WorkPlacePointerShape {
    case `default`
    case roundedRect(CGSize, CGFloat)

    @available(iOS 13.4, *)
    func toPointerShape() -> PointerShape {
        switch self {
        case .default: return .default
        case .roundedRect(let size, let radius): return .roundedSize { (_, _)  in (size, radius) }
        }
    }
}

enum WorkPlacePointerEffect {
    case highlight
    case lift
    case hover

    @available(iOS 13.4, *)
    func toInteraction(_ shape: WorkPlacePointerShape) -> Interaction {
        let effect: PointerEffect
        switch self {
        case .highlight: effect = .highlight
        case .lift: effect = .lift
        case .hover: effect = .hover()
        }
        return PointerInteraction(style: PointerStyle(effect: effect, shape: shape.toPointerShape()))
    }
}

extension UIView {
    func addInteraction(type: WorkPlacePointerEffect, shape: WorkPlacePointerShape = .default) {
        if #available(iOS 13.4, *) {
            addLKInteraction(type.toInteraction(shape))
        }
    }
}

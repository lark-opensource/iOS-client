//
//  UDBadge+Dot.swift
//  UniverseDesignBadge
//
//  Created by Meng on 2020/10/28.
//

import UIKit
import Foundation

/// UDBadgeDotSize
///
/// size with `large`, `middle`, `small`
/// `small` for text, icon, bubble card etc.
/// `middle` for list, feed, text, icon etc.
/// `large` for avatar etc.
///
public enum UDBadgeDotSize {
    /// large size: 10x10 px
    /// @badge-dot-bg-large-radius: @radius-xl
    case large

    /// middle size: 8x8 px
    /// @badge-dot-bg-middle-radius: @radius-xl
    case middle

    /// small size: 6x6 px
    /// @badge-dot-bg-small-radius: @radius-xl
    case small

    /// dot size
    public var size: CGSize {
        switch self {
        case .large:
            return CGSize(width: 10.0, height: 10.0)
        case .middle:
            return CGSize(width: 8.0, height: 8.0)
        case .small:
            return CGSize(width: 6.0, height: 6.0)
        }
    }
}

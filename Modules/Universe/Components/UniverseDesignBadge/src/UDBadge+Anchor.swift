//
//  UDBadge+Anchor.swift
//  UniverseDesignBadge
//
//  Created by Meng on 2020/10/28.
//

import UIKit
import Foundation

/// UDBadgeAnchor
///
/// adjust self size and offset on superview
/// only UDBadgeAnchorType is `none`
///
public enum UDBadgeAnchor: Int {
    /// topLeft anchor
    case topLeft

    /// topRight anchor
    case topRight

    /// bottomLeft anchor
    case bottomLeft

    /// bottomRight anchor
    case bottomRight
}

/// UDBadgeAnchorType
///
/// super view anchor type, auto adjust self size and offset on superview
///
public enum UDBadgeAnchorType: Int {
    /// none anchor, content change will only change self size
    case none

    /// circle anchor, content change will auto adjust self size and offset on superview
    case circle

    /// rectangle anchor, content change will auto adjust self size and offset on superview
    case rectangle
}

/// UDbadgeAnchorExtendType
///
/// badge horizontal extend type
///
public enum UDBadgeAnchorExtendType {
    /// extend leading
    case leading
    /// extend trailing
    case trailing

    var sign: CGFloat {
        switch self {
        case .leading:
            return -1.0
        case .trailing:
            return 1.0
        }
    }
}

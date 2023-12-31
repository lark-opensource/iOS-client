//
//  UDBadge+Type.swift
//  UniverseDesignBadge
//
//  Created by Meng on 2020/10/28.
//

import UIKit
import Foundation

/// UDBadgeType
public enum UDBadgeType {
    /// dot badge
    case dot

    /// text badge
    case text

    /// number badge
    case number

    /// icon badge
    case icon

    /// badge default size
    var defaultSize: CGSize {
        switch self {
        case .dot:
            return UDBadgeDotSize.middle.size
        case .text, .number, .icon:
            return CGSize(width: 16.0, height: 16.0)
        }
    }
}

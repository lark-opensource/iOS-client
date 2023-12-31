//
//  BadgeType.swift
//  LarkTab
//
//  Created by Supeng on 2020/12/16.
//

import UIKit
public enum BadgeType: Equatable {
    case none
    case dot(Int)
    case number(Int)
    case image(UIImage)

    public var count: Int {
        switch self {
        case .number(let num): return num
        case .dot(let num): return num
        default: return 0
        }
    }

    public var description: String {
        switch self {
        case .none:
            return "none"
        case .dot(let number):
            return "dot \(number)"
        case .number(let number):
            return "number \(number)"
        case .image(_):
            return "image"
        }
    }
}

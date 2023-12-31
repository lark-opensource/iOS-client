//
//  KCTAttributedKey.swift
//  LKRichView
//
//  Created by qihongye on 2019/9/3.
//

import UIKit
import Foundation

enum AttributedKey {
    typealias RawValue = String
    case font
    case color
    case backgroundColor

    var rawValue: RawValue {
        switch self {
        case .font:
            return kCTFontAttributeName as String
        case .color:
            return kCTForegroundColorAttributeName as String
        case .backgroundColor:
            return "lkrichview-backgroundColor"
        }
    }

    var nsAttrKey: NSAttributedString.Key {
        return .init(rawValue)
    }
}
